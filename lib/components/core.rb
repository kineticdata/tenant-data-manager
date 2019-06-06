module Kinetic
  module Platform
    class Core
  
      attr_reader :host, :subdomains, :space_slug, :username, :password,
                  :space_name, :space_users

      attr_accessor :service_user_username, :service_user_password

      def initialize(options)
        @host = options["host"]
        @subdomains = options["subdomains"]
        @space_slug = options["space-slug"]
        @username = options["username"] || "admin"
        @password = options["password"] || "admin"
        raise StandardError.new "Core requires a space slug." if @space_slug.nil?

        space = options["space"] || {}
        @space_name = space["name"] || @space_slug
        @space_users = space["users"] || []

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

      def properties
        {
          "api" => api,
          "server" => server,
          "space_slug" => @space_slug,
          "space_name" => @space_name,
          "space_users" => @space_users,
          "username" => @username,
          "password" => @password,
          "service_user_username" => @service_user_username,
          "service_user_password" => @service_user_password
        }
      end

    end # class
  end # module
end # module
