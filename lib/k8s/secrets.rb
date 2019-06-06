require 'base64'
require 'yaml'

module Kinetic
  module Platform
    class Kubernetes

      def self.decode_secret(secret, secrets_file, namespace="default")
        cmd = "kubectl get -n #{namespace} secret #{secrets_file} -o yaml"
        secrets = `#{cmd}`
        if secrets
          data = YAML.load(secrets)["data"]
          value = data[secret]
          value.nil? ? nil : Base64.decode64(value)
        else
          nil
        end
      end

      def self.decode_space_secret(secret, space_slug)
        self.decode_secret(secret, "#{space_slug}-secrets", space_slug)
      end

    end
  end
end
