module Kinetic
  module Platform
    class ActionBase

      attr_reader :action, :slug, :log_level, :templates,
                  :bridgehub, :core, :discussions, :filehub, :task
      
      INSTALL      = "install"
      REPAIR       = "repair"
      UPGRADE      = "upgrade"
      DECOMMISSION = "decommission"
      UNINSTALL    = "uninstall"

      ACTIONS = [ INSTALL, REPAIR, UPGRADE, DECOMMISSION, UNINSTALL ]

      def initialize(options)
        begin
          @action = options["action"]
          @slug = options["slug"]
          @subdomains = options["subdomains"].to_s.strip.downcase == "true"
          @log_level = options["log_level"] || "off"
          @host = options["host"]
          @component_metadata = options["components"] || {}
          @template_metadata = options["templates"] || []
          # validate the arguments
          validate
        rescue Exception => e
          raise e
        end

      end

      def execute
        raise StandardError.new "Not Implemented"
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
        raise "`host` must use http or https protocol." if (@host =~ /^https?:\/\/.+/).nil?
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
          "log_level" => @log_level,
          "username" => Kinetic::Platform::Kubernetes.decode_secret("system_username", "shared-secrets", "kinetic"),
          "password" => Kinetic::Platform::Kubernetes.decode_secret("system_password", "shared-secrets", "kinetic")
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
        http = Http.new(@core.username, @core.password)
        res = http.get("#{@core.system_api}/spaces/#{space_slug}",
          {}, http.default_headers)

        # raise an error if the state of the space slug could not be determined
        if res.status != 200 && res.status != 404
          msg = "#{res.status}: Aborting #{ACTION} of space slug #{space_slug}, #{res.message}"
          raise StandardError.new msg
        end

        # return true if space exists, or false if it doesn't exist
        res.status == 200
      end

    end
  end
end
