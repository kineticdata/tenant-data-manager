module Kinetic
  module Platform
    class Install < Kinetic::Platform::ActionBase

      ACTION = Kinetic::Platform::ActionBase::INSTALL

      def initialize(options)
        super(options.merge({"action" => ACTION}))
      end

      def execute
        # if the space slug was not provided
        if @core.space_slug.nil?
          # keep generating a space slug until an unused one is found
          loop do
            space_slug = generate_space_slug
            break if !space_exists?(space_slug)
          end

          # set the space_slug in all the components
          @bridgehub.space_slug=space_slug
          @core.space_slug=space_slug
          @discussions.space_slug=space_slug
          @filehub.space_slug=space_slug
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
        http = Http.new(@core.username, @core.password)
        payload = { "name" => @core.space_name, "slug" => @core.space_slug }
        url = "#{@core.system_api}/spaces"
        res = http.post(url, payload, http.default_headers)
        if res.status != 200
          msg = "POST #{url} - #{res.status}: #{res.message}"
          Kinetic::Platform.logger.info msg
          return
        end

        # deploy space task application
        Kinetic::Platform.logger.info "Deploying the #{@core.space_name} space task application"
        http = Http.new
        payload = { 
          "tenant" => @core.space_slug,
          "image" => @task.image,
          "tag" => @task.tag
        }
        url = "#{@task.deployer_api}/newTenant"
        res = http.post(url, payload, http.json_headers)
        if res.status != 200
          msg = "POST #{url} - #{res.status}: #{res.message}"
          Kinetic::Platform.logger.info msg
          return
        end

        # wait for ingress to pick up the space subdomain routes
        subdomain_ready, tries, max_tries = false, 0, 30
        url = "#{@core.api}/version"
        loop do
          tries = tries + 1
          Kinetic::Platform.logger.info "Try #{tries}, checking space subdomain at #{url}"
          http = Http.new
          res = http.get(url, {}, http.default_headers)
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
          Kinetic::Platform.logger.info msg
          return
        end

        # set the admin user credentials that will be created in all spaces
        admin_username = "kdadmin"

        # set the service user credentials that will be used by the
        # applications where needed to communicate with each other
        service_user_username = "integration-user"
        service_user_password = Kinetic::Platform::Kubernetes.decode_space_secret(@core.space_slug, @core.service_user_password_key)

        # update the credentials in each application that utilizes the service user
        @bridgehub.service_user_username  = service_user_username
        @bridgehub.service_user_password  = service_user_password
        @core.service_user_username       = service_user_username
        @core.service_user_password       = service_user_password
        @task.service_user_username       = service_user_username
        @task.service_user_password       = service_user_password

        # create the common space admin user using the system api
        Kinetic::Platform.logger.info "Creating user #{admin_username}"
        http = Http.new(@core.username, @core.password)
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
        http = Http.new(@core.username, @core.password)
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
          Kinetic::Platform.logger.info msg
          return
        end

        # create Kinetic Core bridge
        Kinetic::Platform.logger.info "Creating the #{@bridgehub.bridge_slug} bridge"
        http = Http.new(@bridgehub.username, @bridgehub.password)
        bridge_name = "#{@core.space_slug} - #{@core.space_name} - Kinetic Core"
        payload = {
          "adapterClass" => "com.kineticdata.bridgehub.adapter.kineticcore.KineticCoreAdapter",
          "name" => bridge_name,
          "slug" => @bridgehub.bridge_slug,
          "ipAddresses" => "*",
          "useAccessKeys" => "true",
          "properties" => {
            "Username" => service_user_username,
            "Password" => service_user_password,
            "Kinetic Core Space Url" => "#{@core.server}"
          }
        }
        url = "#{@bridgehub.api}/bridges"
        res = http.post(url, payload, http.default_headers)
        if res.status == 200
          # create bridgehub access key
          Kinetic::Platform.logger.info "Creating an access key for the #{@bridgehub.bridge_slug} bridge"
          bridge_access_key_id = Kinetic::Platform::Random.simple(8)
          bridge_access_key_secret = Kinetic::Platform::Random.simple(32)
          payload = {
            "description" => "#{@bridgehub.bridge_slug}",
            "id" => bridge_access_key_id,
            "secret" => bridge_access_key_secret
          }
          url = "#{@bridgehub.api}/bridges/#{@bridgehub.bridge_slug}/access-keys"
          res = http.post(url, payload, http.default_headers)
          if res.status != 200
            Kinetic::Platform.logger.info "POST #{url} - #{res.status}: #{res.message}"
          end

          # update the bridgehub component with the access key info
          @bridgehub.access_key_id = bridge_access_key_id
          @bridgehub.access_key_secret = bridge_access_key_secret
        else
          Kinetic::Platform.logger.info "POST #{url} - #{res.status}: #{res.message}"
        end

        # create filehub filestore
        Kinetic::Platform.logger.info "Creating the #{@filehub.filestore_slug} filestore"
        http = Http.new(@filehub.username, @filehub.password)
        payload = { 
          "name" => "#{@filehub.filestore_slug}",
          "slug" => @filehub.filestore_slug,
          "adapterClass" => @filehub.adapter_class,
          "properties" => @filehub.adapter_properties
        }
        url = "#{@filehub.api}/filestores"
        res = http.post(url, payload, http.default_headers)
        if res.status == 200
          # create filestore access key
          Kinetic::Platform.logger.info "Creating an access key for the #{@filehub.filestore_slug} filestore"
          filestore_access_key_id = Kinetic::Platform::Random.simple(8)
          filestore_access_key_secret = Kinetic::Platform::Random.simple(32)
          payload = {
            "description" => "#{@filehub.filestore_slug}",
            "id" => filestore_access_key_id,
            "secret" => filestore_access_key_secret
          }
          url = "#{@filehub.api}/filestores/#{@filehub.filestore_slug}/access-keys"
          res = http.post(url, payload, http.default_headers)
          if res.status != 200
            Kinetic::Platform.logger.info "POST #{url} - #{res.status}: #{res.message}"
          end

          # update the filehub component with the access key info
          @filehub.access_key_id = filestore_access_key_id
          @filehub.access_key_secret = filestore_access_key_secret
        else
          Kinetic::Platform.logger.info "POST #{url} - #{res.status}: #{res.message}"
        end

        # create space oauth clients for the service user
        Kinetic::Platform.logger.info "Creating the #{@core.space_name} space oauth client for #{service_user_username}"
        http = Http.new(service_user_username, service_user_password)
        payload = {
          "name" => service_user_username,
          "description" => "OAuth client for #{service_user_username}",
          "clientId" => service_user_username,
          "clientSecret" => service_user_password,
          "redirectUri" => "#{@core.server}/#/OAuthCallback"
        }
        url = "#{@core.api}/oauthClients"
        res = http.post(url, payload, http.default_headers)
        if res.status != 200
          Kinetic::Platform.logger.info "POST #{url} - #{res.status}: #{res.message}"
        end

        # create space oauth clients for task
        Kinetic::Platform.logger.info "Creating the #{@core.space_name} space oauth client for task"
        oauth_id_task = "kinetic-task"
        oauth_secret_task = Kinetic::Platform::Random.simple(32)
        http = Http.new(service_user_username, service_user_password)
        payload = {
          "name" => "Kinetic Task",
          "description" => "OAuth client for Kinetic Task",
          "clientId" => oauth_id_task,
          "clientSecret" => oauth_secret_task,
          "redirectUri" => "#{@task.server}/oauth"
        }
        url = "#{@core.api}/oauthClients"
        res = http.post(url, payload, http.default_headers)

        if res.status == 200
          # Wait for task to be running
          task_is_running, tries, max_tries = false, 0, 5
          url = "#{@task.api}"
          loop do
            tries = tries + 1
            Kinetic::Platform.logger.info "Try #{tries}, checking task status at #{url}"
            http = Http.new
            res = http.get(url, {}, {})
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
            # update task to use core as identity store
            Kinetic::Platform.logger.info "Updating the #{@core.space_name} space task identity store to use core"

            # Get the task password from the secret store
            @task.password=Kinetic::Platform::Kubernetes.decode_space_secret(@task.space_slug, @task.password_key)

            # add the task license
            if !@task.license.nil?
              Kinetic::Platform.logger.info "Importing the #{@core.space_name} task license"
              http = Http.new(@task.username, @task.password)
              payload = { "licenseContent" => @task.license }
              url = "#{@task.api_v2}/config/license"
              res = http.post(url, payload, http.default_headers)
            end

            http = Http.new(@task.username, @task.password)
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

            # update task to use oauth
            Kinetic::Platform.logger.info "Updating the #{@core.space_name} task authentication to use oauth"
            http = Http.new(@task.username, @task.password)
            payload = {
              "authenticator" => "com.kineticdata.core.v1.authenticators.OAuthAuthenticator",
              "authenticationJsp" => "/WEB-INF/app/login.jsp",
              "properties" => {
                # Kinetic Task OAuth Properties
                "Provider Name" => "Core",
                "Auto Redirect Login" => "Yes",
                # OAuth Provider Endpoint Properties
                "Authorize Endpoint" => "#{@core.server}/app/oauth/authorize",
                "Token Endpoint" => "#{@core.server}/app/oauth/token",
                "Check Token Endpoint" => "#{@core.server}/app/oauth/check_token?token=",
                "Logout Redirect Location" => "#{@core.server}/app/logout",
                # OAuth Client Properties
                "Client Id" => oauth_id_task,
                "Client Secret" => oauth_secret_task,
                "Redirect URI" => "#{@task.server}/oauth",
                "Scope" => "full_access"
              }
            }
            url = "#{@task.api_v2}/config/auth"
            res = http.put(url, payload, http.default_headers)
          else
            msg = "The #{ACTION} action for the #{@core.space_slug} space failed. Task did not startup in the allowable timeframe."
            Kinetic::Platform.logger.info msg
            return
          end
        else
          Kinetic::Platform.logger.info "POST #{url} - #{res.status}: #{res.message}"
        end

        # decode any template data secrets
        @template_data_secrets.each do |key, secrets_file|
          @template_data = @template_data.merge({
            key => Kinetic::Platform::Kubernetes.decode_secrets_file(secrets_file)
          })
        end

        # process each of the templates
        @templates.each do |template|
          template.install
          if File.readable?(template.script_path)
            script_variables = {
              "bridgehub" => @bridgehub.template_bindings,
              "core" => @core.template_bindings,
              "discussions" => @discussions.template_bindings,
              "filehub" => @filehub.template_bindings,
              "task" => @task.template_bindings,
              "data" => @template_data
            }
            Kinetic::Platform.logger.info "Running #{template.script} in the #{template.name}:#{template.version} repository."
            Kinetic::Platform.logger.info "  #{template.script_path}"
            # Kinetic::Platform.logger.info "Script Data: "
            # Kinetic::Platform.logger.info "  #{script_variables.to_json}"

            system("ruby", template.script_path, script_variables.to_json)
          else
            Kinetic::Platform.logger.warn "Skipping #{ACTION} action of #{template.name}:#{template.version} because the #{template.script_path} file doesn't exist."
          end
        end
        
        Kinetic::Platform.logger.info "#{ACTION} space #{@core.space_slug} complete"
        "#{ACTION} complete"
      end
      
    end
  end
end
