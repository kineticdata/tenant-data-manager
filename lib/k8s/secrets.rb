require 'base64'
require 'yaml'

module Kinetic
  module Platform
    class Kubernetes

      def self.decode_secret(secrets_file, secret_key, namespace="kinetic")
        cmd = "kubectl get -n #{namespace} secret #{secrets_file} -o yaml"
        secrets = `#{cmd}`
        if secrets
          secret_content = YAML.load(secrets) || {}
          data = secret_content["data"] || {}
          value = data[secret_key]
          value.nil? ? nil : Base64.decode64(value)
        else
          nil
        end
      end

      def self.decode_secrets_file(secrets_file, namespace="kinetic")
        cmd = "kubectl get -n #{namespace} secret #{secrets_file} -o yaml"
        secrets = `#{cmd}`
        if secrets
          secret_content = YAML.load(secrets) || {}
          (secret_content["data"] || {}).inject({}) do |memo, (key,value)|
            memo[key] = Base64.decode64(value)
            memo
          end
        else
          {}
        end
      end

      def self.decode_space_secret(space_slug, secret_key, namespace="kinetic")
        self.decode_secret("#{space_slug}-secrets", secret_key, "kinetic-tenant-#{space_slug}", namespace)
      end

      def self.decode_space_secrets_file(space_slug, secrets_file, namespace="kinetic")
        self.decode_secrets_file("#{space_slug}-secrets", "kinetic-tenant-#{space_slug}", namespace)
      end

    end
  end
end
