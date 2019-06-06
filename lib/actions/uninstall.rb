module Kinetic
  module Platform
    class Uninstall < Kinetic::Platform::ActionBase

      ACTION = Kinetic::Platform::ActionBase::UNINSTALL

      def initialize(options)
        super(options.merge({"action" => ACTION}))
      end

      def execute
        Kinetic::Platform.logger.info "Deleting the task database for space #{@task.space_slug}"
        http = Http.new
        payload = { "tenant" => @task.space_slug }
        url = "#{@task.deployer_api}/deleteTenantDb"
        res = http.post(url, payload, http.json_headers)
        if res.status != 200
          Kinetic::Platform.logger.info "#{res.status}: #{res.message}"
          throw StandardError.new res.message
        end

        # Don't think there is a way to do this currently
        Kinetic::Platform.logger.info "Deleting the files in the filestore for space #{@filehub.space_slug}"

        "#{ACTION} complete"
      end

    end
  end
end
