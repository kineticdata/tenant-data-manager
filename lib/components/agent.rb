module Kinetic
  module Platform
    class Agent

      attr_reader :host, :username, :password, :component_type
      attr_accessor :space_slug, :service_user_username, :service_user_password
      
      def initialize(options)
        @host = options["host"]
        @subdomains = options["subdomains"]
        @space_slug = options["space_slug"]
        @username = options["username"] || "admin"
        @password = options["password"] || "admin"

        @component_type = "agent"

        @service_user_username, @service_user_password = nil, nil
      end

      def server
        "#{@host}/kinetic-agent"
      end

      def bridge_api
        "/app/api/v1/bridges"
      end

      def bridge_slug
        "kinetic-core"
      end

      def bridge_path
        "#{bridge_api}/#{bridge_slug}"
      end

      def filestore_api
        "/app/api/v1/filestores"
      end

      def template_bindings
        {
          "component_type" => @component_type,
          "bridge_api" => bridge_api,
          "bridge_path" => bridge_path,
          "bridge_slug" => bridge_slug,
          "filestore_api" => filestore_api,
          "service_user_username" => @service_user_username,
          "service_user_password" => @service_user_password,
          "space_slug" => @space_slug
        }
      end

    end # class
  end #module
end # module
