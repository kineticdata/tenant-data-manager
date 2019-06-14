module Kinetic
  module Platform
    class ActionBase

      attr_reader :action, :slug, :log_level, :templates,
                  :bridgehub, :core, :discussions, :filehub, :task
      
      INSTALL      = "install"
      REPAIR       = "repair"
      UPGRADE      = "upgrade"
      DECOMMISSION = "decommission"
      UNINSTALL    = "uninstall"

      ACTIONS = [ INSTALL, REPAIR, UPGRADE, DECOMMISSION, UNINSTALL ]

      def initialize(options)
        begin
          @action = options["action"]
          @slug = options["slug"]
          @subdomains = options["subdomains"].to_s.strip.downcase == "true"
          @log_level = options["log_level"] || "off"
          @host = options["host"]
          @component_metadata = options["components"]
          @template_metadata = options["templates"]
          # validate the arguments
          validate
        rescue Exception => e
          raise e
        end

      end

      def execute
        raise StandardError.new "Not Implemented"
      end


      private

      def validate
        validate_action
        validate_slug
        validate_host
        validate_components
        validate_templates
      end

      def validate_action
        raise "`action` must be one of: #{ACTIONS.join(',')}." unless 
          ACTIONS.include?(@action)
      end

      def validate_slug
        raise "`slug` cannot be blank." if @slug.to_s.strip.empty?
      end

      def validate_host
        raise "`host` cannot be blank." if @host.to_s.strip.empty?
        raise "`host` must use http or https protocol." if (@host =~ /^https?:\/\/.+/).nil?
        raise "`host` must not end with a forward slash." if (@host =~ /[^\/]$/).nil?
      end

      def validate_components
        raise "`components` must be a hash or object of platform component information." if
          !@component_metadata.is_a?(Hash) || @component_metadata.empty?

        options = { 
          "host"     => @host,
          "space_slug" => @slug,
          "subdomains" => @subdomains,
          "log_level" => @log_level
        }
        @component_metadata.map do |key,item|
          case key
          when "bridgehub"
            @bridgehub = Kinetic::Platform::Bridgehub.new(options.merge(item))
          when "core"
            @core = Kinetic::Platform::Core.new(options.merge(item))
          when "discussions"
            @discussions = Kinetic::Platform::Discussions.new(options.merge(item))
          when "filehub"
            @filehub = Kinetic::Platform::Filehub.new(options.merge(item))
          when "task"
            @task = Kinetic::Platform::Task.new(options.merge(item))
          end
        end
      end

      def validate_templates
        if %(install repair upgrade).include?(@action)
          if !@template_metadata.is_a?(Array)
            raise "`templates` must be an array of template information."
          end
          # install each of the templates
          @templates = @template_metadata.map do |item|
            Kinetic::Platform::Template.new(@action, item)
          end
        end
      end

    end
  end
end
