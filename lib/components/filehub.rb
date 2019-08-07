module Kinetic
  module Platform
    class Filehub

      attr_reader :host, :username, :password,
                  :adapter_class, :adapter_properties

      attr_accessor :space_slug, :access_key_id, :access_key_secret
      
      def initialize(options)
        @host = options["host"]
        @subdomains = options["subdomains"]
        @space_slug = options["space_slug"]
        @username = options["username"] || "admin"
        @password = options["password"] || "admin"

        @access_key_id, @access_key_secret = nil, nil

        adapter = options["adapter"] || {}
        @adapter_class = adapter["class"] || adapter_class()
        @adapter_properties = adapter["properties"] || adapter_properties()
      end

      def server
        "#{@host}/kinetic-filehub"
      end

      def api
        "#{server}/app/api/v1"
      end

      def filestore_slug
        "#{@space_slug}"
      end

      def filestore_path
        "#{server}/filestores/#{filestore_slug}"
      end

      def template_bindings
        {
          "api" => api,
          "server" => server,
          "space_slug" => @space_slug,
          "filestores" => {
            "kinetic-core" => {
              "access_key_id" => @access_key_id,
              "access_key_secret" => @access_key_secret,
              "filestore_path" => filestore_path,
              "slug" => filestore_slug
            }
          }
        }
      end

      def adapter_class
        ENV['FILESTORE_ADAPTER_CLASS']
      end

      def adapter_grouping_property
        ENV['FILESTORE_GROUPING_PROPERTY']
      end

      def adapter_grouping_prefix
        ENV['FILESTORE_GROUPING_PREFIX']
      end
      def adapter_properties
        {
          "Name" => @space_slug,
          "Slug" => filestore_slug,
          adapter_grouping_property => "#{adapter_grouping_prefix}/#{@space_slug}"
        }.merge(adapter_secrets)
      end

      def adapter_secrets
        Kinetic::Platform::Kubernetes.decode_secrets_file("filestore-secrets")
      end

    end # class
  end #module
end # module
