require 'json'
require 'fileutils'

module Kinetic
  module Platform
    class Template

      attr_reader :name, :url, :version, :version_type,
                  :install_dir, :script, :script_path, :script_args

      TEMPLATES_DIR = "template-repos"

      VERSION_TYPE_BRANCH = "branch"
      VERSION_TYPE_COMMIT = "commit"
      VERSION_TYPE_TAG = "tag"

      VERSION_TYPES = [ VERSION_TYPE_BRANCH, VERSION_TYPE_COMMIT, VERSION_TYPE_TAG ]


      # Template represents a Git repository that contains Core definitions
      # (space, kapps, forms, category definitions, etc...), Task definitions
      # (handlers, trees, routines, etc...), and some files to indicate how to 
      # install, upgrade, repair a space that uses the repository.
      #
      # action - action to use when provisioning: `install`, `repair`, `upgrade`
      # options - hash of template options
      #   +url+ - the url of the Git repository (must use HTTP or HTTPS)
      #   +branch+ - the branch to checkout (default `master`), error if
      #              `commit` and/or `tag` is also provided
      #   +commit+ - the commit hash to checkout, error if `branch` and/or `tag`
      #              is also provided
      #   +tag+    - the tag to checkout, error if `branch` and/or `commit` is 
      #              also provided
      #   +script+ - the name of the script to run (default `#{action}.rb`)
      #   +script-args+ - JSON hash of optional arguments to pass to the script
      #                   (default `"{}"`)
      #
      # Templates installed using a tag or commit will be cached for re-use. Any
      # templates using a branch will be cloned for each use to ensure there were
      # no modifications to the branch since it was last run, and to prevent
      # changing the contents by doing a `git pull` while multiple provisioners
      # are running simultaneously.
      #
      # As a minimum, templates must define the following files in the root
      # of the project:
      #   +install.rb+ - default file to run during an `install` action
      #   +repair.rb+ - default file to run during a `repair` action
      #   +upgrade.rb+ - default file to run during an `upgrade` action
      #
      def initialize(action, options)
        raise "template options must be a hash or object" if !options.is_a?(Hash)
        raise "template `url` cannot be blank." if options["url"].to_s.strip.size == 0
        raise "template `url` must begin with http or https: #{options['url']}" if (options["url"] =~ /https?:\/\//).nil?
        if (options.has_key?(VERSION_TYPE_BRANCH) && (options.has_key?(VERSION_TYPE_TAG) || options.has_key?(VERSION_TYPE_COMMIT))) ||
          (options.has_key?(VERSION_TYPE_TAG) && (options.has_key?(VERSION_TYPE_BRANCH) || options.has_key?(VERSION_TYPE_COMMIT))) ||
          (options.has_key?(VERSION_TYPE_COMMIT) && (options.has_key?(VERSION_TYPE_BRANCH) || options.has_key?(VERSION_TYPE_TAG)))
            raise "template options may only include one of `#{VERSION_TYPE_BRANCH}`, `#{VERSION_TYPE_TAG}`, `#{VERSION_TYPE_COMMIT}`"
        end
        raise "template `#{VERSION_TYPE_TAG}` cannot be blank." if options.has_key?(VERSION_TYPE_TAG) && options[VERSION_TYPE_TAG].to_s.strip.size == 0
        raise "template `#{VERSION_TYPE_COMMIT}` cannot be blank." if options.has_key?(VERSION_TYPE_COMMIT) && options[VERSION_TYPE_COMMIT].to_s.strip.size == 0
      
        @name = options["url"].split("/").last.gsub(".git", "")
        @url = options["url"]
        @version = options[VERSION_TYPE_COMMIT] || options[VERSION_TYPE_TAG] || options[VERSION_TYPE_BRANCH] || "master"
        @version_type = options.has_key?(VERSION_TYPE_COMMIT) ? VERSION_TYPE_COMMIT :
                        options.has_key?(VERSION_TYPE_TAG) ? VERSION_TYPE_TAG :
                        VERSION_TYPE_BRANCH
        @install_dir = [VERSION_TYPE_COMMIT, VERSION_TYPE_TAG].include?(@version_type) ? 
                        "#{@name}-#{@version}" : "#{@name}-#{Time.now.to_i}"
        @script = options["script"] || "#{action}.rb"
        @script_path = File.join(templates_path, @install_dir, @script)
        @script_args = options["script-args"] || {}
      end

      # When using a branch, the repository will always be cloned into a 
      # directory that contains the current timestamp appended to the repository
      # name. These directories will then be uninstalled when the provisioner
      # completes because the directory will never be used again due to the
      # dynamic state of the code.
      #
      # When using either a commit or tag, the repository will be cloned to a
      # directory that contains the commit has or tag name appended to the
      # repository name. These directories will not be removed as they can be 
      # reused as they represent a static or frozen state of code.

      def install
        Kinetic::Platform.logger.info "Preparing Git repository for template: #{@name}"
        FileUtils.cd(templates_path) do
          if @version_type == VERSION_TYPE_BRANCH || !Dir.exist?(@install_dir)
            system("git clone #{@url} #{@install_dir}")
            FileUtils.cd(@install_dir) do
              system("git checkout #{@version}")
            end
          end
        end
      end

      def uninstall
        if (@version_type == VERSION_TYPE_BRANCH)
          Kinetic::Platform.logger.info "Removing Git repository for template: #{@name}"
          Dir.chdir(templates_path) do
            FileUtils.rm_r(@install_dir, :force => true)
          end
        end
      end


      private

      def templates_path
        File.expand_path(File.join(__dir__, "..", TEMPLATES_DIR))
      end

    end
  end
end
