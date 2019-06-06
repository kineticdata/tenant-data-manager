module Kinetic
  module Platform
    class Bridgehub

      attr_reader :host, :space_slug, :username, :password,
                  :bridge_slug

      attr_accessor :service_user_username, :service_user_password
      
      def initialize(options)
        @host = options["host"]
        @subdomains = options["subdomains"]
        @space_slug = options["space-slug"]
        @username = options["username"] || "admin"
        @password = options["password"] || "admin"
        raise StandardError.new "Bridgehub requires a space slug." if @space_slug.nil?

        @bridge_slug = "ce-#{@space_slug}"

        @service_user_username = nil
        @service_user_password = nil
      end

      def server
        "#{@host}/kinetic-bridgehub"
      end

      def api
        "#{server}/app/manage-api/v1"
      end

      def properties
        {
          "api" => api,
          "bridge_slug" => @bridge_slug,
          "server" => server,
          "space_slug" => @space_slug,
          "username" => @username,
          "password" => @password,
          "service_user_username" => @service_user_username,
          "service_user_password" => @service_user_password
        }
      end

    end # class
  end #module
end # module
