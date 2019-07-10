module Kinetic
  module Platform
    class Discussions

      attr_reader :host, :subdomains,
                  :oauth_client_id, :oauth_client_secret, :log_level
      
      attr_accessor :space_slug
      
      def initialize(options)
        @host = options["host"]
        @subdomains = options["subdomains"]
        @log_level = options["log_level"]
        @space_slug = options["space_slug"]

        oauth_client = options["oauth-client"] || {}
        @oauth_client_id = oauth_client["id"] || "kinetic-bundle"
        @oauth_client_secret = oauth_client["secret"] || Kinetic::Platform::Random.simple
      end

      def server
        @host
      end

      def api
        if @subdomains
          "#{server.gsub("://", "://#{@space_slug}.")}/app/discussions/api/v1"
        else
          "#{server}/#{@space_slug}/app/discussions/api/v1"
        end
      end

      def template_bindings
        {
          "api" => api,
          "log_level" => @log_level,
          "server" => server,
          "space_slug" => @space_slug
        }
      end

    end # class
  end #module
end # module
