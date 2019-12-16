module Kinetic
  module Platform
    class Core
  
      attr_reader :host, :subdomains, :username, :password, :space_name,
                  :service_user_password_key

      attr_accessor :space_slug, :service_user_username, :service_user_password

      SERVICE_USER_PASSWORD_KEY = "INTEGRATION_USER_PASSWORD"

      def initialize(options)
        @host = options["host"]
        @subdomains = options["subdomains"]
        @space_slug = options["space_slug"]
        @username = options["username"] || "admin"
        @password = options["password"] || "admin"
        @service_user_password_key = SERVICE_USER_PASSWORD_KEY

        space = options["space"] || {}
        @space_name = space["name"] || @space_slug

        @service_user_username = options["service_user_username"]
        @service_user_password = nil
      end

      def server
        if @subdomains
          "#{@host.gsub("://", "://#{@space_slug}.")}"
        else
          "#{@host}/#{@space_slug}"
        end
      end

      def system_api
        "#{@host}/app/api/v1"
      end

      def api
        "#{server}/app/api/v1"
      end

      def proxy_url
        "#{server}/app/components"
      end

      def agent_api(agent_slug="system")
        "#{proxy_url}/agent/#{agent_slug}/app/api/v1"
      end

      def task_api_v1
        "#{proxy_url}/task/app/api/v1"
      end

      def task_api_v2
        "#{proxy_url}/task/app/api/v2"
      end

      def template_bindings
        {
          "api" => api(),
          "agent_api" => agent_api(),
          "proxy_url" => proxy_url(),
          "server" => server(),
          "space_slug" => @space_slug,
          "space_name" => @space_name,
          "service_user_username" => @service_user_username,
          "service_user_password" => @service_user_password,
          "task_api_v1" => task_api_v1(),
          "task_api_v2" => task_api_v2()
        }
      end

    end # class
  end # module
end # module
