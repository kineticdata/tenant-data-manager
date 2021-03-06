module Kinetic
  module Platform
    class Bridgehub

      attr_reader :host, :username, :password, :component_type
      attr_accessor :space_slug, :service_user_username, :service_user_password
      
      def initialize(options)
        @host = options["host"]
        @subdomains = options["subdomains"]
        @space_slug = options["space_slug"]
        @username = options["username"] || "admin"
        @password = options["password"] || "admin"

        @component_type = "bridgehub"

        @service_user_username = options["service_user_username"]
        @service_user_password = nil
      end

      def server
        "#{@host}/kinetic-bridgehub"
      end

      def api
        "#{server}/app/api/v1"
      end

      def client_api
        "#{server}/#{@space_slug}/app/api/v1"
      end

      def bridge_slug
        "kinetic-core"
      end

      def bridge_path
        "#{client_api}/bridges/#{bridge_slug}"
      end

      def template_bindings
        {
          "api" => api,
          "client_api" => client_api,
          "server" => server,
          "space_slug" => @space_slug,
          "bridges" => {
            "kinetic-core" => {
              "bridge_path" => bridge_path,
              "slug" => bridge_slug,
              "component_type" => @component_type
            }
          }
        }
      end

    end # class
  end #module
end # module
