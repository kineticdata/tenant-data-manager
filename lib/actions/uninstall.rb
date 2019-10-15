module Kinetic
  module Platform
    class Uninstall < Kinetic::Platform::ActionBase

      ACTION = Kinetic::Platform::ActionBase::UNINSTALL

      def initialize(options)
        super(options.merge({"action" => ACTION}))
      end

      def execute
        timing_start = Time.now

        Kinetic::Platform.logger.info "Deleting the task database for space #{@task.space_slug}"
        http = Http.new(@task.provisioner_username, @task.provisioner_password, @internal_http_options)
        payload = { "tenant" => @task.space_slug }
        url = "#{@task.deployer_api}/deleteTenantDb"
        res = http.post(url, payload, http.default_headers)
        if res.status != 200
          Kinetic::Platform.logger.info "#{res.status}: #{res.message}"
          throw StandardError.new res.message
        end

        # Don't think there is a way to do this currently
        Kinetic::Platform.logger.info "Deleting the files in the filestore for space #{@filehub.space_slug}"


        duration = duration(timing_start)
        Kinetic::Platform.logger.info "#{ACTION} space #{@core.space_slug} complete (#{duration})"
        "#{ACTION} complete (#{duration})"
      end

    end
  end
end
