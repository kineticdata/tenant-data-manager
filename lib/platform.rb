require 'logger'

module Kinetic
  module Platform
    extend self
    attr_accessor :logger

    self.logger = Logger.new(STDERR)
    self.logger.level = Logger::INFO
    self.logger.formatter = proc do |severity, datetime, progname, msg|
      date_format = datetime.utc.strftime("%Y-%m-%dT%H:%M:%S.%LZ")
      "[#{date_format}] #{severity}: #{msg}\n"
    end

    def self.usage
      props = %w(action slug host subdomains components templates )
      "Options for the provisioner must contain the following properties: #{props.join(', ')}"
    end

  end
end
