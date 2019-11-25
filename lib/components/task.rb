module Kinetic
  module Platform
    class Task
    
      attr_reader :host, :subdomains, :username, :password_key, :component_type,
                  :license, :provisioner_username, :provisioner_password

      attr_accessor :space_slug, :image, :tag, :password, :signature_secret

      CONFIGURATOR_USERNAME = "admin"
      CONFIGURATOR_PASSWORD_KEY = "CONFIGURATOR_PASSWORD_PLAINTEXT"

      def initialize(options)
        @host = options["host"]
        @subdomains = options["subdomains"]
        @space_slug = options["space_slug"]
        @username = CONFIGURATOR_USERNAME
        @password_key = CONFIGURATOR_PASSWORD_KEY
        @license = options["license"]
        
        @provisioner_username = ENV['BASIC_AUTH_USERNAME']
        @provisioner_password = ENV['BASIC_AUTH_PASSWORD']

        @component_type = "task"

        container = options["container"] || {}
        @image = container["image"]
        @tag = container["tag"]

        @password = nil
        @signature_secret = nil
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
        "https://tenant-infrastructure-manager.kinetic.svc.cluster.local"
      end

      def template_bindings
        {
          "api" => api,
          "api_v2" => api_v2,
          "component_type" => @component_type,
          "server" => server,
          "space_slug" => @space_slug,
          "signature_secret" => @signature_secret
        }
      end

    end # class
  end # module
end # module
