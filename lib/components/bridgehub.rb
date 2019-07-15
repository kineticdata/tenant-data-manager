module Kinetic
  module Platform
    class Bridgehub

      attr_reader :host, :username, :password

      attr_accessor :space_slug, :access_key_id, :access_key_secret,
                    :service_user_username, :service_user_password
      
      def initialize(options)
        @host = options["host"]
        @subdomains = options["subdomains"]
        @space_slug = options["space_slug"]
        @username = options["username"] || "admin"
        @password = options["password"] || "admin"

        @access_key_id, @access_key_secret = nil, nil
        @service_user_username, @service_user_password = nil, nil
      end

      def server
        "#{@host}/kinetic-bridgehub"
      end

      def api
        "#{server}/app/manage-api/v1"
      end

      def client_api
        "#{server}/app/api/v1"
      end

      def bridge_slug
        "#{@space_slug.to_s}-core"
      end

      def bridge_path
        "#{client_api}/bridges/#{bridge_slug}"
      end

      def template_bindings
        {
          "api" => api,
          "server" => server,
          "space_slug" => @space_slug,
          "bridges" => {
            "kinetic-core" => {
              "access_key_id" => @access_key_id,
              "access_key_secret" => @access_key_secret,
              "bridge_path" => bridge_path,
              "slug" => bridge_slug
            }
          }
        }
      end

    end # class
  end #module
end # module
