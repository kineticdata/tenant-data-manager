module Kinetic
  module Platform
    class GravityInstall

      require 'deep_merge'

      attr_reader :action, :slug, :templates, :callback,
                  :agent, :core, :discussions, :task,
                  :http_options, :template_data

      GRAVITY_INSTALL = "gravity_install"
      DEFAULT_NAMESPACE = "kinetic"

      ACTIONS = [ GRAVITY_INSTALL ]


      def initialize(options)
        begin
          @action = options["action"] || GRAVITY_INSTALL
          @slug = options["slug"]
          @namespace = options["namespace"] || DEFAULT_NAMESPACE
          @subdomains = true
          @host = options["host"]
          @space = options["space"] || {}
          @callback = options["callback"] || {}
          @component_metadata = options["components"] || {}
          @template_metadata = options["templates"] || []

          http_options = options["http_options"] || {}
          @http_options = {
            :log_level => http_options["log_level"] || "off",
            :log_output => http_options["log_output"] || "STDERR",
            :gateway_retry_limit => (http_options["gateway_retry_limit"] || 5).to_i,
            :gateway_retry_delay => (http_options["gateway_retry_delay"] || 1.0).to_f,
            # changed this to 'none' instead of 'peer'
            :ssl_verify_mode => http_options["ssl_verify_mode"] || "none"
          }

          # build the extra data to send to templates
          # add decoded template data secrets first, then merge in the rest of the
          # template data to allow overwriting values that were provided as stored secrets
          @template_data = Kinetic::Platform::GravityInstall.prepare_template_data(options["templateData"], options["templateDataSecrets"])

          # validate the arguments
          validate

          Kinetic::Platform.logger.info("Task Server: #{@task.server}")
          Kinetic::Platform.logger.info("Argument Options: #{options}")
        rescue Exception => e
          raise e
        end
      end

      def execute
        begin
          timing_start = Time.now
          # if the space slug was not provided
          if @core.space_slug.nil?
            msg = "Aborting template install, the space slug cannot be null"
            Kinetic::Platform.logger.info msg
            raise StandardError.new(msg)
          else
            # if the space slug was pre-generated
            if !space_exists?(@core.space_slug)
              msg = "Aborting template install, the space with the slug #{@core.space_slug} does not exist."
              Kinetic::Platform.logger.info msg
              raise StandardError.new(msg)
            else
              msg = "The space slug #{@core.space_slug} does not exist, continuing with the template install action."
              Kinetic::Platform.logger.info msg
            end
          end

          # process each of the templates
          @templates.each do |template|
            template.install
            if File.readable?(template.script_path)
              script_variables = script_data({
                "agent" => @agent.template_bindings,
                "core" => @core.template_bindings,
                "discussions" => @discussions.template_bindings,
                "task" => @task.template_bindings
              }, template.script_args)
              Kinetic::Platform.logger.info "Running #{template.script} in the #{template.name}:#{template.version} repository."
              Kinetic::Platform.logger.info "  #{template.script_path}"

              system("ruby", template.script_path, script_variables.to_json)
            else
              Kinetic::Platform.logger.warn "Skipping template install action of #{template.name}:#{template.version} because the #{template.script_path} file doesn't exist."
            end
          end

          message = "Template installation in space #{@core.space_slug} complete"
          status = "Complete"
          value = "Completed successfully"
        rescue Exception => e
          message = e.message
          status = "Failed"
          value = "Template install failed: #{message}"
        ensure
          Kinetic::Platform.logger.info(message += " (#{duration(timing_start)})")
        end
        
        # return the results
        {
          "message" => message,
          "status" => status,
          "value" => value
        }
      end

      def callback(results)
        update_space(results) if @callback['status']
        complete_deferred_task(results) if @callback['url']
      end

      def duration(start, finish=Time.now)
        "%.3f sec" % (finish-start)
      end

      def self.prepare_template_data(template_data, template_secret_data)
        data = (template_secret_data || {}).each_with_object({}) do |(key,value),result|
          Kinetic::Platform::GravityInstall.decode_secrets(key, value, result)
        end
        data.deep_merge!(template_data || {})
      end

      def self.decode_secrets(key, value, memo={})
        if value.is_a?(Hash)
          memo[key] = value.each_with_object({}) do |(k,v),r| 
            Kinetic::Platform::GravityInstall.decode_secrets(k, v, r)
          end
        else
          memo[key] = Kinetic::Platform::Kubernetes.decode_secrets_file(value)
        end
        memo
      end


      private

      ###############################################
      # callback methods
      ###############################################

      def update_space(results)
        status = "Active"
        status_message = results["value"]
        
        Kinetic::Platform.logger.info "Updating the space status"
        http = Http.new(@core.username, @core.password, @http_options)
        url = "#{@core.system_api}/spaces/#{@core.space_slug}"
        payload = { "status" => status, "statusMessage" => status_message }
        res = http.put(url, payload, http.default_headers)
        if res.status != 200
          msg = "PUT #{url} - #{res.status}: #{res.message}"
          Kinetic::Platform.logger.error msg
        end
      end

      def complete_deferred_task(results)
        message = results["message"]
        status = results["status"]

        url = @callback['url']
        if url
          Kinetic::Platform.logger.info "Completing the deferred task at #{url}"
          http = Http.new(@core.service_user_username, manage_space_password(), @http_options)
          results_xml = %|
            <results>
              <result name="message">#{escape_xml(message)}</result>
              <result name="status">#{escape_xml(status)}</result>
            </results>
          |
          payload = { "message" => message, "results" => results_xml }
          res = http.post(url, payload, http.default_headers)
          if res.status != 200
            msg = "POST #{url} - #{res.status}: #{res.message}"
            Kinetic::Platform.logger.error msg
            return
          end
        end
      end

      def escape_xml(string)
        escape_map = {'&'=>'&amp;', '>'=>'&gt;', '<'=>'&lt;', '"' => '&quot;'}
        string.to_s.gsub(/[&"><]/) { |special| escape_map[special] } if string
      end


      ###############################################
      # validation methods
      ###############################################

      def validate
        validate_action
        validate_slug
        validate_host
        validate_components
        validate_templates
      end

      def validate_action
        raise "`action` must be one of: #{ACTIONS.join(',')}." unless 
          ACTIONS.include?(@action)
      end

      def manage_space_password
        manage_slug = ENV["MANAGE_SPACE_SLUG"] || "manage"
        Kinetic::Platform::Kubernetes.decode_space_secret(manage_slug, "INTEGRATION_USER_PASSWORD")
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
          "namespace" => @namespace,
          "space_slug" => @slug,
          "subdomains" => @subdomains,
          "username" => Kinetic::Platform::Kubernetes.decode_secret("shared-secrets", "system_username"),
          "password" => Kinetic::Platform::Kubernetes.decode_secret("shared-secrets", "system_password"),
          "service_user_username" => Kinetic::Platform::Kubernetes.decode_secret("#{@slug}-secrets", "INTEGRATION_USER_USERNAME", "#{@namespace}-tenant-#{@slug}"),
          "service_user_password" => Kinetic::Platform::Kubernetes.decode_secret("#{@slug}-secrets", "INTEGRATION_USER_PASSWORD", "#{@namespace}-tenant-#{@slug}"),
          "space" => @space
        }

        # Create the components if they were defined in the passed in data
        @component_metadata.map do |key,item|
          case key
          when "agent"
            @agent = Kinetic::Platform::Agent.new(options.merge(item))
          when "core"
            @core = Kinetic::Platform::Core.new(options.merge(item))
          when "discussions"
            @discussions = Kinetic::Platform::Discussions.new(options.merge(item))
          when "task"
            @task = Kinetic::Platform::Task.new(options.merge(item))
          end
        end

        # Create any components that were not defined in the passed in data
        @agent = Kinetic::Platform::Agent.new(options) if @agent.nil?
        @core = Kinetic::Platform::Core.new(options) if @core.nil?
        @discussions = Kinetic::Platform::Discussions.new(options) if @discussions.nil?
        @task = Kinetic::Platform::Task.new(options) if @task.nil?
      end

      def validate_templates
        if [ GRAVITY_INSTALL ].include?(@action)
          if !@template_metadata.is_a?(Array)
            raise "`templates` must be an array of template information."
          end
          # install each of the templates
          @templates = @template_metadata.map do |item|
            Kinetic::Platform::Template.new(@action, item)
          end
        end
      end

      def space_exists?(space_slug)
        # check if space slug is already used
        Kinetic::Platform.logger.info "Ensuring the #{space_slug} space exists"
        http = Http.new(@core.username, @core.password, @http_options)
        url = "#{@core.system_api}/spaces/#{space_slug}"
        Kinetic::Platform.logger.info "GET #{url}"
        res = http.get(url, {}, http.default_headers)

        # raise an error if the state of the space slug could not be determined
        if res.status != 200 && res.status != 404
          msg = "#{res.status}: Aborting template install of space slug #{space_slug}, #{res.message}"
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
