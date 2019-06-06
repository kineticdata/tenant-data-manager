module Kinetic
  module Platform
    module HttpUtils

      #-------------------------------------------------------------------------
      # Instance methods that are duplicated as module/class methods
      #-------------------------------------------------------------------------

      # Provides an Accept header set to application/json
      #
      # @return [Hash] Accept header set to application/json
      def header_accept_json
        { "Accept" => "application/json" }
      end

      # Provides a basic authentication header
      # 
      # @param username [String] username to authenticate
      # @param password [String] password associated to the username
      # @return [Hash] Authorization: Basic base64 hash of username and password
      def header_basic_auth(username=@username, password=@password)
        { "Authorization" => "Basic #{Base64.encode64(username.to_s + ":" + password.to_s).gsub("\n", "")}" }
      end

      # Provides a Bearer authentication header
      # 
      # @param token [String] JSON Web Token (jwt)
      # @return [Hash] Authorization: Bearer jwt
      def header_bearer_auth(token=@jwt)
        { "Authorization" => "Bearer #{token}" }
      end

      # Provides a content-type header set to application/json
      #
      # @return [Hash] Content-Type header set to application/json
      def header_content_json
        { "Content-Type" => "application/json" }
      end

      # Provides a hash of default headers
      #
      # @param username [String] username to authenticate
      # @param password [String] password associated to the username
      # @return [Hash] Hash of headers
      #   - Accepts: application/json
      #   - Authorization: Basic base64 hash of username and password if username is provided
      #   - Content-Type: application/json
      def default_headers(username=@username, password=@password)
        headers = header_accept_json.merge(header_content_json)
        headers.merge!(header_basic_auth(username, password)) unless username.nil?
        headers
      end

      # Provides a hash of default headers with bearer auth instead of basic auth
      #
      # @param token [String] JSON Web Token (jwt)
      # @return [Hash] Hash of headers
      #   - Accepts: application/json
      #   - Authorization: Bearer jwt
      #   - Content-Type: application/json
      def default_jwt_headers(token=@jwt)
        headers = header_accept_json.merge(header_content_json)
        headers.merge!(header_bearer_auth(token)) unless token.nil?
        headers
      end

      # Provides a hash of json headers
      #
      # @return [Hash] Hash of headers
      #   - Accepts: application/json
      #   - Content-Type: application/json
      def json_headers
        header_accept_json.merge(header_content_json)
      end

    end
  end
end
