module Kinetic
  module Platform
    class Core
  
      attr_reader :host, :subdomains, :username, :password, :space_name,
                  :log_level

      attr_accessor :space_slug, :service_user_username, :service_user_password

      def initialize(options)
        @host = options["host"]
        @log_level = options["log_level"]
        @subdomains = options["subdomains"]
        @space_slug = options["space_slug"]
        @username = options["username"] || "admin"
        @password = options["password"] || "admin"

        space = options["space"] || {}
        @space_name = space["name"] || @space_slug

        @service_user_username = nil
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

      def template_bindings
        {
          "api" => api,
          "log_level" => @log_level,
          "server" => server,
          "space_slug" => @space_slug,
          "space_name" => @space_name,
          "service_user_username" => @service_user_username,
          "service_user_password" => @service_user_password
        }
      end

    end # class
  end # module
end # module
