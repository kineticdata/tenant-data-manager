module Kinetic
  module Platform
    class Task
    
      attr_reader :host, :subdomains, :username, :password_key, :license,
                  :log_level

      attr_accessor :space_slug, :image, :tag, :password,
                    :service_user_username, :service_user_password

      DEFAULT_CONTAINER_IMAGE = "kineticdata/kinetic-task"
      DEFAULT_CONTAINER_TAG   = "latest"

      def initialize(options)
        @host = options["host"]
        @subdomains = options["subdomains"]
        @log_level = options["log_level"]
        @space_slug = options["space_slug"]
        @username = options["username"] || "admin"
        @password_key = options["password"]
        @license = options["license"]

        container = options["container"] || {}
        @image = container["image"] || DEFAULT_CONTAINER_IMAGE
        @tag = container["tag"] || DEFAULT_CONTAINER_TAG

        @password = nil
        @service_user_username = nil
        @service_user_password = nil
      end

      def server
        if @subdomains
          "#{@host.gsub("://", "://#{@space_slug}.")}/kinetic-task"
        else
          "#{@host}/#{@space_slug}/kinetic-task"
        end
      end

      def api
        "#{server}/app/api/v1"
      end

      def api_v2
        "#{server}/app/api/v2"
      end

      def deployer_api
        "http://tenant-infrastructure-manager"
      end

      def template_bindings
        {
          "api" => api,
          "api_v2" => api_v2,
          "log_level" => @log_level,
          "server" => server,
          "space_slug" => @space_slug,
          "username" => @username,
          "password" => @password,
          "service_user_username" => @service_user_username,
          "service_user_password" => @service_user_password
        }
      end

    end # class
  end # module
end # module
