module Kinetic
  module Platform
    class ActionBase

      require 'deep_merge'

      attr_reader :action, :slug, :templates,
                  :bridgehub, :core, :discussions, :filehub, :task,
                  :http_options, :internal_http_options, :template_data

      INSTALL      = "install"
      REPAIR       = "repair"
      UPGRADE      = "upgrade"
      DECOMMISSION = "decommission"
      UNINSTALL    = "uninstall"

      ACTIONS = [ INSTALL, REPAIR, UPGRADE, DECOMMISSION, UNINSTALL ]


      def self.prepare_template_data(template_data, template_secret_data)
        data = (template_secret_data || {}).each_with_object({}) do |(key,value),result|
          self.decode_secrets(key, value, result)
        end
        data.deep_merge!(template_data || {})
      end

      def self.decode_secrets(key, value, memo={})
        if value.is_a?(Hash)
          memo[key] = value.each_with_object({}) { |(k,v),r| self.decode_secrets(k, v, r) }
        else
          memo[key] = Kinetic::Platform::Kubernetes.decode_secrets_file(value)
        end
        memo
      end


      def initialize(options)
        begin
          @action = options["action"]
          @slug = options["slug"]
          @subdomains = options["subdomains"].nil? ? true : 
              options["subdomains"].to_s.strip.downcase == "true"
          @host = options["host"]
          @component_metadata = options["components"] || {}
          @template_metadata = options["templates"] || []

          http_options = options["http_options"] || {}
          @http_options = {
            :log_level => http_options["log_level"] || "off",
            :log_output => http_options["log_output"] || "STDERR",
            :gateway_retry_limit => (http_options["gateway_retry_limit"] || 5).to_i,
            :gateway_retry_delay => (http_options["gateway_retry_delay"] || 1.0).to_f,
            :ssl_ca_file => http_options["ssl_ca_file"] || "/etc/ssl/ca.crt",
            :ssl_verify_mode => http_options["ssl_verify_mode"] || "peer"
          }
          @internal_http_options = {
            :log_level => @http_options[:log_level],
            :log_output => @http_options[:log_output],
            :gateway_retry_limit => @http_options[:gateway_retry_limit],
            :gateway_retry_delay => @http_options[:gateway_retry_delay],
            :ssl_ca_file => "/app/cert/tls.crt",
            :ssl_verify_mode => "peer"
          }

          # build the extra data to send to templates
          # add decoded template data secrets first, then merge in the rest of the
          # template data to allow overwriting values that were provided as stored secrets
          @template_data = self.prepare_template_data(options["templateData"], options["templateDataSecrets"])

          # validate the arguments
          validate
        rescue Exception => e
          raise e
        end
      end

      def execute
        raise StandardError.new "Not Implemented"
      end

      def duration(start, finish=Time.now)
        "%.3f sec" % (finish-start)
      end


      private

      def validate
        validate_action
        validate_slug unless @action == INSTALL
        validate_host
        validate_components
        validate_templates
      end

      def validate_action
        raise "`action` must be one of: #{ACTIONS.join(',')}." unless 
          ACTIONS.include?(@action)
      end

      def validate_slug
        raise "`slug` cannot be blank." if @slug.to_s.strip.empty?
      end

      def validate_host
        raise "`host` cannot be blank." if @host.to_s.strip.empty?
        raise "`host` must use http[s] protocol." if (@host =~ /^https?:\/\/.+/).nil?
        raise "`host` must not end with a forward slash." if (@host =~ /[^\/]$/).nil?
      end

      def validate_components

        if !@component_metadata.is_a?(Hash)
          raise "`components` must be a hash or object of platform component information."
        end
          
        options = { 
          "host"     => @host,
          "space_slug" => @slug,
          "subdomains" => @subdomains,
          "username" => Kinetic::Platform::Kubernetes.decode_secret("shared-secrets", "system_username"),
          "password" => Kinetic::Platform::Kubernetes.decode_secret("shared-secrets", "system_password")
        }

        # Create the components if they were defined in the passed in data
        @component_metadata.map do |key,item|
          case key
          when "bridgehub"
            @bridgehub = Kinetic::Platform::Bridgehub.new(options.merge(item))
          when "core"
            @core = Kinetic::Platform::Core.new(options.merge(item))
          when "discussions"
            @discussions = Kinetic::Platform::Discussions.new(options.merge(item))
          when "filehub"
            @filehub = Kinetic::Platform::Filehub.new(options.merge(item))
          when "task"
            @task = Kinetic::Platform::Task.new(options.merge(item))
          end
        end

        # Create any components that were not defined in the passed in data
        @bridgehub = Kinetic::Platform::Bridgehub.new(options) if @bridgehub.nil?
        @core = Kinetic::Platform::Core.new(options) if @core.nil?
        @discussions = Kinetic::Platform::Discussions.new(options) if @discussions.nil?
        @filehub = Kinetic::Platform::Filehub.new(options) if @filehub.nil?
        @task = Kinetic::Platform::Task.new(options) if @task.nil?
      end

      def validate_templates
        if %(install repair upgrade).include?(@action)
          if !@template_metadata.is_a?(Array)
            raise "`templates` must be an array of template information."
          end
          # install each of the templates
          @templates = @template_metadata.map do |item|
            Kinetic::Platform::Template.new(@action, item)
          end
        end
      end

      def generate_space_slug
        rand(9999999).to_s.rjust(7,'0')
      end

      def space_exists?(space_slug)
        # check if space slug is already used
        Kinetic::Platform.logger.info "Checking if the #{space_slug} space slug is already installed"
        http = Http.new(@core.username, @core.password, @http_options)
        res = http.get("#{@core.system_api}/spaces/#{space_slug}",
          {}, http.default_headers)

        # raise an error if the state of the space slug could not be determined
        if res.status != 200 && res.status != 404
          msg = "#{res.status}: Aborting provisioning action of space slug #{space_slug}, #{res.message}"
          raise StandardError.new msg
        end

        # return true if space exists, or false if it doesn't exist
        res.status == 200
      end

      def script_data(component_data, script_arguments)
        data = {
          "http_options" => @http_options,
          "data" => @template_data
        }
        data = data.merge(component_data) if component_data.is_a?(Hash)
        data = data.merge(script_arguments) if script_arguments.is_a?(Hash)
        data
      end

    end
  end
end
