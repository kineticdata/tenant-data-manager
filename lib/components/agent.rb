module Kinetic
  module Platform
    class Agent

      attr_reader :agent_slug, :host, :username, :password, :component_type
      attr_accessor :space_slug
      
      def initialize(options)
        @host = options["host"]
        @subdomains = options["subdomains"]
        @agent_slug = options["agent_slug"] || "system"
        @space_slug = options["space_slug"]
        @username = options["username"] || "admin"
        @password = options["password"] || "admin"

        @component_type = "agent"
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
          "agent_slug" => @agent_slug,
          "component_type" => @component_type,
          "bridge_api" => bridge_api,
          "bridge_path" => bridge_path,
          "bridge_slug" => bridge_slug,
          "filestore_api" => filestore_api,
          "space_slug" => @space_slug
        }
      end

    end # class
  end #module
end # module
