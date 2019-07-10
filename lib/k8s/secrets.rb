require 'base64'
require 'yaml'

module Kinetic
  module Platform
    class Kubernetes

      def self.decode_secret(secret_key, secrets_file, namespace="kinetic")
        cmd = "kubectl get -n #{namespace} secret #{secrets_file} -o yaml"
        secrets = `#{cmd}`
        if secrets
          data = YAML.load(secrets)["data"]
          value = data[secret_key]
          value.nil? ? nil : Base64.decode64(value)
        else
          nil
        end
      end

      def self.decode_space_secret(secret_key, space_slug)
        self.decode_secret(secret_key, "#{space_slug}-secrets", "kinetic-tenant-#{space_slug}")
      end

    end
  end
end
