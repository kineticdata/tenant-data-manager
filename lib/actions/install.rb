module Kinetic
  module Platform
    class Install < Kinetic::Platform::ActionBase

      ACTION = Kinetic::Platform::ActionBase::INSTALL

      def initialize(options)
        super(options.merge({"action" => ACTION}))
      end

      def execute
        timing_start = Time.now

        # if the space slug was not provided
        if @core.space_slug.nil?
          # keep generating a space slug until an unused one is found
          loop do
            space_slug = generate_space_slug
            break if !space_exists?(space_slug)
          end

          # set the space_slug in all the components
          @core.space_slug=space_slug
          @discussions.space_slug=space_slug
          @task.space_slug=space_slug
        else
          # if the space slug was pre-generated
          if space_exists?(@core.space_slug)
            msg = "Aborting #{ACTION}, a space with the slug #{@core.space_slug} already exists."
            Kinetic::Platform.logger.info msg
            return
          else
            msg = "The space slug #{@core.space_slug} does not exist, continuing with the #{ACTION} action."
            Kinetic::Platform.logger.info msg
          end
        end

        # create the space using the system api
        Kinetic::Platform.logger.info "Creating the #{@core.space_name} space with slug #{@core.space_slug}"
        http = Http.new(@core.username, @core.password, @http_options)
        payload = { "name" => @core.space_name, "slug" => @core.space_slug }
        url = "#{@core.system_api}/spaces"
        res = http.post(url, payload, http.default_headers)
        if res.status != 200
          msg = "POST #{url} - #{res.status}: #{res.message}"
          Kinetic::Platform.logger.error msg
          return
        end

        # deploy space task application
        Kinetic::Platform.logger.info "Deploying the #{@core.space_name} space task application"
        http = Http.new(@task.provisioner_username, @task.provisioner_password, @internal_http_options)
        payload = { "tenant" => @core.space_slug }
        payload["image"] = @task.image if !@task.image.nil?
        payload["tag"] = @task.tag if !@task.tag.nil?

        url = "#{@task.deployer_api}/newTenant"
        res = http.post(url, payload, http.default_headers)
        if res.status != 200
          msg = "POST #{url} - #{res.status}: #{res.message}"
          Kinetic::Platform.logger.error msg
          return
        end

        # wait for ingress to pick up the space subdomain routes
        subdomain_ready, tries, max_tries = false, 0, 30
        url = "#{@core.api}/version"
        loop do
          tries = tries + 1
          Kinetic::Platform.logger.info "Try #{tries}, checking space subdomain at #{url}"
          http = Http.new(nil, nil, @http_options)
          res = http.get(url, {}, http.default_headers, { :gateway_retry_limit => -1 })
          if res.status == 200
            Kinetic::Platform.logger.info "  #{res.status}: space subdomain is ready"
            subdomain_ready = true
            break
          end
          Kinetic::Platform.logger.info "  #{res.status}: #{res.message}, space subdomain is not ready"
          break if tries >= max_tries || res.status == 0
          sleep 1
        end

        if !subdomain_ready
          msg = "The #{ACTION} action for the #{@core.space_slug} space failed. The space cannot be reached."
          Kinetic::Platform.logger.error msg
          return
        end

        # set the admin user credentials that will be created in all spaces
        admin_username = "kdadmin"

        # set the service user credentials that will be used by the
        # applications where needed to communicate with each other
        service_user_username = "integration-user"
        service_user_password = Kinetic::Platform::Kubernetes.decode_space_secret(@core.space_slug, @core.service_user_password_key)

        # TODO: REMOVE PRINT
        Kinetic::Platform.logger.info "Integration User Password: #{service_user_password}"

        # update the credentials in each application that utilizes the service user
        @agent.service_user_username = service_user_username
        @agent.service_user_password = service_user_password
        @core.service_user_username  = service_user_username
        @core.service_user_password  = service_user_password
        @task.service_user_username  = service_user_username
        @task.service_user_password  = service_user_password

        # create the common space admin user using the system api
        Kinetic::Platform.logger.info "Creating user #{admin_username}"
        http = Http.new(@core.username, @core.password, @http_options)
        payload = {
          "space_slug" => @core.space_slug,
          "username" => admin_username,
          "password" => Kinetic::Platform::Random.simple(24),
          "enabled" => true,
          "spaceAdmin" => true
        }
        url = "#{@core.system_api}/spaces/#{@core.space_slug}/users"
        res = http.post(url, payload, http.default_headers)


        # create the space specific service user using the system api
        Kinetic::Platform.logger.info "Creating user #{service_user_username}"
        http = Http.new(@core.username, @core.password, @http_options)
        payload = {
          "space_slug" => @core.space_slug,
          "username" => service_user_username,
          "password" => service_user_password,
          "enabled" => true,
          "spaceAdmin" => true
        }
        url = "#{@core.system_api}/spaces/#{@core.space_slug}/users"
        res = http.post(url, payload, http.default_headers)
        if res.status != 200
          msg = "POST #{url} - #{res.status}: #{res.message}"
          Kinetic::Platform.logger.error msg
          return
        end

        # create kinetic core bridge using the platform component proxy
        Kinetic::Platform.logger.info "Creating the #{@agent.bridge_slug} bridge"
        http = Http.new(service_user_username, service_user_password, @http_options)
        payload = {
          "adapterClass" => "com.kineticdata.bridgehub.adapter.kineticcore.v2.KineticCoreAdapter",
          "slug" => @agent.bridge_slug,
          "properties" => {
            "Username" => service_user_username,
            "Password" => service_user_password,
            "Kinetic Core Space Url" => "#{@core.server}"
          }
        }
        url = "#{@core.agent_api}/bridges"
        Kinetic::Platform.logger.info "  POST #{url}"
        res = http.post(url, payload, http.default_headers)
        if res.status != 200
          Kinetic::Platform.logger.warn "POST #{url} - #{res.status}: #{res.message}"
        end

        # configure the task platform component
        Kinetic::Platform.logger.info "Configuring the #{@core.space_name} task platform component"
        @task.signature_secret = Kinetic::Platform::Random.simple(32)

        # TODO: REMOVE PRINT
        Kinetic::Platform.logger.info "Signature Authenticator Secret: #{@task.signature_secret}"
        
        http = Http.new(service_user_username, service_user_password, @http_options)
        payload = {
          "platformComponents" => {
            "task" => {
              "secret" => @task.signature_secret,
              "url" => @task.server
            }
          }
        }
        url = "#{@core.api}/space"
        res = http.put(url, payload, http.default_headers)

        if res.status == 200
          # Wait for task to be running
          task_is_running, tries, max_tries = false, 0, 36
          url = "#{@task.api}"
          loop do
            tries = tries + 1
            Kinetic::Platform.logger.info "Try #{tries}, checking task status at #{url}"
            http = Http.new(nil, nil, @http_options)
            res = http.get(url, {}, {}, { :gateway_retry_limit => -1 })
            if res.status == 200
              Kinetic::Platform.logger.info "  #{res.status}: task is running"
              task_is_running = true
              break
            end
            Kinetic::Platform.logger.info "  #{res.status}: #{res.message}, task is not running"
            if tries >= max_tries || res.status == 0
              Kinetic::Platform.logger.info "#{ACTION} did not complete successfully. Task is not running."
              break
            end
            sleep 5
          end

          if task_is_running
            # Get the task password from the secret store
            @task.password=Kinetic::Platform::Kubernetes.decode_space_secret(@task.space_slug, @task.password_key)
            if @task.password.nil?
              Kinetic::Platform.logger.warn "WARNING - Invalid task configurator user credentials - #{@task.username}:#{@task.password}"
            end

            # TODO: REMOVE PRINT
            Kinetic::Platform.logger.info "Task Configurator Password: #{@task.password}"
            
            # add the task license
            if !@task.license.nil?
              Kinetic::Platform.logger.info "Importing the #{@core.space_name} task license"
              http = Http.new(@task.username, @task.password, @http_options)
              payload = { "licenseContent" => @task.license }
              url = "#{@task.api_v2}/config/license"
              res = http.post(url, payload, http.default_headers)
            end

            # delete the playground source
            Kinetic::Platform.logger.info "Deleting the task Playground source"
            http = Http.new(@task.username, @task.password, @http_options)
            url = "#{@task.api_v2}/sources/Playground"
            res = http.delete(url, http.default_headers)

            # delete all console policy rules to use system default
            http = Http.new(@task.username, @task.password, @http_options)
            type = "Console Access"
            url = "#{@task.api_v2}/policyRules/#{http.encode(type)}"
            res = http.get(url, {}, http.default_headers)
            if res.status == 200
              res.content['policyRules'].each do |policyRule|
                name = policyRule['name']
                Kinetic::Platform.logger.info "Deleting the #{name} console policy rule"
                url = "#{@task.api_v2}/policyRules/#{http.encode(type)}/#{http.encode(name)}"
                res = http.delete(url, http.default_headers)
              end
            end

            # update task to use core as identity store
            Kinetic::Platform.logger.info "Updating #{@core.space_name} task to use core as an identity store."
            http = Http.new(@task.username, @task.password, @http_options)
            payload = {
              "Identity Store" => "com.kineticdata.authentication.kineticcore.KineticCoreIdentityStore",
              "properties" => {
                "Kinetic Core Space Url" => "#{@core.server}",
                "Proxy Username (Space Admin)" => service_user_username,
                "Proxy Password (Space Admin)" => service_user_password
              }
            }
            url = "#{@task.api_v2}/config/identityStore"
            res = http.put(url, payload, http.default_headers)

            # update task to use signature authentication
            Kinetic::Platform.logger.info "Updating #{@core.space_name} task to use signature authentication"
            http = Http.new(@task.username, @task.password, @http_options)
            payload = {
              "authenticator" => "com.kineticdata.core.v1.authenticators.SignatureAuthenticator",
              "properties" => {
                "Secret" => @task.signature_secret
              }
            }
            url = "#{@task.api_v2}/config/auth"
            res = http.put(url, payload, http.default_headers)
          else
            msg = "The #{ACTION} action for the #{@core.space_slug} space failed. Task did not startup in the allowable timeframe."
            Kinetic::Platform.logger.error msg
            return
          end
        else
          Kinetic::Platform.logger.info "PUT #{url} - #{res.status}: #{res.message}"
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
            Kinetic::Platform.logger.warn "Skipping #{ACTION} action of #{template.name}:#{template.version} because the #{template.script_path} file doesn't exist."
          end
        end
        
        duration = duration(timing_start)
        Kinetic::Platform.logger.info "#{ACTION} space #{@core.space_slug} complete (#{duration})"
        "#{ACTION} complete (#{duration})"
      end
      
    end
  end
end
