module Kinetic
  module Platform
    class Decommission < Kinetic::Platform::ActionBase

      ACTION = Kinetic::Platform::ActionBase::DECOMMISSION

      def initialize(options)
        super(options.merge({"action" => ACTION}))
      end

      def execute
        timing_start = Time.now

        # 1 - remove the task tenant
        Kinetic::Platform.logger.info "Deleting the task container for space #{@task.space_slug}"
        http = Http.new
        payload = { "tenant" => @task.space_slug }
        url = "#{@task.deployer_api}/deleteTenant"
        res = http.post(url, payload, http.json_headers)

        # 2 - remove the bridge
        Kinetic::Platform.logger.info "Deleting the bridge for space #{@bridgehub.space_slug}"
        http = Http.new(@bridgehub.username, @bridgehub.password)
        url = "#{@bridgehub.api}/bridges/#{@bridgehub.bridge_slug}"
        res = http.delete(url, http.default_headers)

        # 3 - remove the filestore
        Kinetic::Platform.logger.info "Deleting the filestore for space #{@filehub.space_slug}"
        http = Http.new(@filehub.username, @filehub.password)
        url = "#{@filehub.api}/filestores/#{@filehub.filestore_slug}"
        res = http.delete(url, http.default_headers)

        # 4 - remove the space
        Kinetic::Platform.logger.info "Deleting the space #{@core.space_slug}"
        http = Http.new(@core.username, @core.password)
        url = "#{@core.system_api}/spaces/#{@core.space_slug}"
        http.delete(url, http.default_headers)


        duration = duration(timing_start)
        Kinetic::Platform.logger.info "#{ACTION} space #{@core.space_slug} complete (#{duration})"
        "#{ACTION} complete (#{duration})"
      end

    end
  end
end
