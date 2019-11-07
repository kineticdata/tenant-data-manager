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
        http = Http.new(@task.provisioner_username, @task.provisioner_password, @internal_http_options)
        payload = { "tenant" => @task.space_slug }
        url = "#{@task.deployer_api}/deleteTenant"
        res = http.post(url, payload, http.default_headers)

        # 2 - remove the bridge
        Kinetic::Platform.logger.info "Deleting the bridge for space #{@core.space_slug}"
        http = Http.new(@core.username, @core.password, @http_options)
        url = "#{@agent.server}/app/api/v1/spaces/#{@agent.space_slug}/bridges/#{@agent.bridge_slug}"
        Kinetic::Platform.logger.info "  DELETE #{url}"
        res = http.delete(url, http.default_headers)

        # 3 - remove the space
        Kinetic::Platform.logger.info "Deleting the space #{@core.space_slug}"
        http = Http.new(@core.username, @core.password, @http_options)
        url = "#{@core.system_api}/spaces/#{@core.space_slug}"
        Kinetic::Platform.logger.info "  DELETE #{url}"
        http.delete(url, http.default_headers)


        duration = duration(timing_start)
        Kinetic::Platform.logger.info "#{ACTION} space #{@core.space_slug} complete (#{duration})"
        "#{ACTION} complete (#{duration})"
      end

    end
  end
end
