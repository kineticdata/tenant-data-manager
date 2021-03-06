module Kinetic
  module Platform
    class Upgrade < Kinetic::Platform::ActionBase

      ACTION = Kinetic::Platform::ActionBase::UPGRADE

      def initialize(options)
        super(options.merge({"action" => ACTION}))
      end

      def execute
        begin
          timing_start = Time.now

          @task.image = "look up from space datastore record or attribute"

          # 1 - check if space slug exists
          Kinetic::Platform.logger.info "Checking if the #{@core.space_slug} space slug exists"
          http = Http.new(@core.username, @core.password, @http_options)
          res = http.get("#{@core.system_api}/spaces/#{@core.space_slug}",
            {}, http.default_headers)

          if res.status == 200
            # define upgrade process


            # process each of the templates, template is responsible for upgrading data
            @templates.each do |template|
              template.install
              if File.readable?(template.script_path)
                Kinetic::Platform.logger.warn "Running #{template.script} in the #{template.name}:#{template.version} repository."
                Kinetic::Platform.logger.warn "  #{template.script_path}"
                script_variables = script_data({
                  "agent" => @agent.template_bindings,
                  "core" => @core.template_bindings,
                  "discussions" => @discussions.template_bindings,
                  "task" => @task.template_bindings
                }, template.script_args)
                system("ruby", template.script_path, script_variables.to_json)
              else
                Kinetic::Platform.logger.warn "Skipping #{ACTION} action of #{template.name}:#{template.version} because the #{template.script} file doesn't exist."
              end
            end

          elsif res.status == 404
            msg = "Aborting #{ACTION}, the space with slug #{@core.space_slug} doesn't exist."
            Kinetic::Platform.logger.warn msg
          else
            msg = "#{res.status}: Aborting  #{ACTION} of space #{@core.space_slug}, #{res.message}"
            Kinetic::Platform.logger.warn msg
            raise StandardError.new(msg)
          end
          
          message = "#{ACTION} space #{@core.space_slug} complete"
          status = "Complete"
        rescue Exception => e
          message = e.message
          status = "Failed"
        ensure
          duration = duration(timing_start)
          message += " (#{duration})"
          Kinetic::Platform.logger.info message
        end
        
        # return the results
        {
          "message" => message,
          "status" => status
        }
      end

    end
  end
end
