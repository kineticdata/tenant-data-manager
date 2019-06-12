module Kinetic
  module Platform
    class Filehub

      attr_reader :host, :space_slug, :username, :password,
                  :filestore_slug, :adapter_class, :adapter_properties

      attr_accessor :access_key_id, :access_key_secret
      
      def initialize(options)
        @host = options["host"]
        @subdomains = options["subdomains"]
        @space_slug = options["space-slug"]
        @username = options["username"] || "admin"
        @password = options["password"] || "admin"
        raise StandardError.new "Filehub requires a space slug." if @space_slug.nil?

        @filestore_slug = "#{@space_slug}-core"

        @access_key_id, @access_key_secret = nil, nil

        adapter = options["adapter"] || {}
        @adapter_class = adapter["class"] || default_adapter["class"]
        @adapter_properties = adapter["properties"] || default_adapter["properties"]
      end

      def server
        "#{@host}/kinetic-filehub"
      end

      def api
        "#{server}/app/api/v1"
      end

      def default_adapter
        {
          "class" => "com.kineticdata.filehub.adapters.local.LocalFilestoreAdapter",
          "properties" => {
            "Directory" => local_directory
          }
        }
      end

      def local_directory
        # TODO: Need to be able to use the filestore slug in the directory path,
        # but currently there is no way to create this directory, so sharing the
        # root directory already created on the file system. This may cause 
        # problems if multiple spaces are created.

        # "/home/filesDirectory/#{@filestore_slug}"
        "/home/filesDirectory"
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
              "filestore_path" => "#{server}/filestores/#{@filestore_slug}",
              "slug" => @filestore_slug
            }
          }
        }
      end

    end # class
  end #module
end # module
