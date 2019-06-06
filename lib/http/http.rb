require 'base64'
require 'erb'
require 'net/http'
require 'openssl'

module Kinetic
  module Platform

    # The HttpUtils module provides common HTTP methods, and returns a 
    # {Kinetic::Platform::HttpResponse} object with all methods. The raw 
    # Net::HTTPResponse is available by calling the 
    # {Kinetic::Platform::HttpResponse#response} method.
    module HttpUtils

      # Send an HTTP GET request
      # 
      # @param url [String] url to send the request to
      # @param params [Hash] Query parameters that are added to the URL, such as +include+
      # @param headers [Hash] hash of headers to send
      # @param redirect_limit [Fixnum] max number of times to redirect
      # @return [Kinetic::Platform::HttpResponse] response
      def get(url, params={}, headers={}, redirect_limit=max_redirects)
        # parse the URL
        uri = URI.parse(url)
        # add URL parameters
        uri.query = URI.encode_www_form(params)

        # build the http object
        http = build_http(uri)
        # build the request
        request = Net::HTTP::Get.new(uri.request_uri, headers)

        # send the request
        begin
          response = http.request(request)
          # handle the response
          case response
          when Net::HTTPRedirection then
            if redirect_limit == -1
              HttpResponse.new(response)
            elsif redirect_limit == 0
              raise Net::HTTPFatalError.new("Too many redirects", response)
            else
              get(response['location'], params, headers, redirect_limit - 1)
            end
          when NilClass then
            raise Net::HTTPFatalError.new("No response from server", response)
          else
            HttpResponse.new(response)
          end
        rescue StandardError => e
          HttpResponse.new(e)
        end
      end

      # Send an HTTP POST request
      # 
      # @param url [String] url to send the request to
      # @param data [Hash] the payload to send with the request
      # @param headers [Hash] hash of headers to send
      # @param redirect_limit [Fixnum] max number of times to redirect
      # @return [Kinetic::Platform::HttpResponse] response
      def post(url, data={}, headers={}, redirect_limit=max_redirects)
        # parse the URL
        uri = URI.parse(url)

        # unless the data is already a string, assume JSON and convert to string
        data = data.to_json unless data.is_a? String
        # build the http object
        http = build_http(uri)
        # build the request
        request = Net::HTTP::Post.new(uri.request_uri, headers)
        request.body = data

        # send the request
        begin
          response = http.request(request)
          # handle the response
          case response
          when Net::HTTPRedirection then
            if redirect_limit == -1
              HttpResponse.new(response)
            elsif redirect_limit == 0
              raise Net::HTTPFatalError.new("Too many redirects", response)
            else
              post(response['location'], data, headers, redirect_limit - 1)
            end
          when NilClass then
            raise Net::HTTPFatalError.new("No response from server", response)
          else
            HttpResponse.new(response)
          end
        rescue StandardError => e
          HttpResponse.new(e)
        end
      end

      # Send an HTTP PUT request
      # 
      # @param url [String] url to send the request to
      # @param data [Hash] payload to send with the request
      # @param headers [Hash] hash of headers to send
      # @param redirect_limit [Fixnum] max number of times to redirect
      # @return [Kinetic::Platform::HttpResponse] response
      def put(url, data={}, headers={}, redirect_limit=max_redirects)
        # parse the URL
        uri = URI.parse(url)

        # unless the data is already a string, assume JSON and convert to string
        data = data.to_json unless data.is_a? String
        # build the http object
        http = build_http(uri)
        # build the request
        request = Net::HTTP::Put.new(uri.request_uri, headers)
        request.body = data

        # send the request
        begin
          response = http.request(request)
          # handle the response
          case response
          when Net::HTTPRedirection then
            if redirect_limit == -1
              HttpResponse.new(response)
            elsif redirect_limit == 0
              raise Net::HTTPFatalError.new("Too many redirects", response)
            else
              put(response['location'], data, headers, redirect_limit - 1)
            end
          when NilClass then
            raise Net::HTTPFatalError.new("No response from server", response)
          else
            HttpResponse.new(response)
          end
        rescue StandardError => e
          HttpResponse.new(e)
        end
      end

      # Send an HTTP DELETE request
      # 
      # @param url [String] url to send the request to
      # @param headers [Hash] hash of headers to send
      # @param redirect_limit [Fixnum] max number of times to redirect
      # @return [Kinetic::Platform::HttpResponse] response
      def delete(url, headers={}, redirect_limit=max_redirects)
        # parse the URL
        uri = URI.parse(url)

        # build the http object
        http = build_http(uri)
        # build the request
        request = Net::HTTP::Delete.new(uri.request_uri, headers)

        # send the request
        begin
          response = http.request(request)
          # handle the response
          case response
          when Net::HTTPRedirection then
            if redirect_limit == -1
              HttpResponse.new(response)
            elsif redirect_limit == 0
              raise Net::HTTPFatalError.new("Too many redirects", response)
            else
              delete(response['location'], headers, redirect_limit - 1)
            end
          when NilClass then
            raise Net::HTTPFatalError.new("No response from server", response)
          else
            HttpResponse.new(response)
          end
        rescue StandardError => e
          HttpResponse.new(e)
        end
      end

      # Send an HTTP HEAD request
      # 
      # @param url [String] url to send the request to
      # @param params [Hash] Query parameters that are added to the URL, such as +include+
      # @param headers [Hash] hash of headers to send
      # @param redirect_limit [Fixnum] max number of times to redirect
      # @return [Kinetic::Platform::HttpResponse] response
      def head(url, params={}, headers={}, redirect_limit=max_redirects)
        # parse the URL
        uri = URI.parse(url)
        # add URL parameters
        uri.query = URI.encode_www_form(params)

        # build the http object
        http = build_http(uri)
        # build the request
        request = Net::HTTP::Head.new(uri.request_uri, headers)

        # send the request
        begin
          response = http.request(request)
          # handle the response
          case response
          when Net::HTTPRedirection then
            if redirect_limit == -1
              HttpResponse.new(response)
            elsif redirect_limit == 0
              raise Net::HTTPFatalError.new("Too many redirects", response)
            else
              head(response['location'], params, headers, redirect_limit - 1)
            end
          when NilClass then
            raise Net::HTTPFatalError.new("No response from server", response)
          else
            HttpResponse.new(response)
          end
        rescue StandardError => e
          HttpResponse.new(e)
        end
      end

      # Determine the final redirect location
      # 
      # @param url [String] url to send the request to
      # @param params [Hash] Query parameters that are added to the URL, such as +include+
      # @param headers [Hash] hash of headers to send
      # @param redirect_limit [Fixnum] max number of times to redirect
      # @return [String] redirection url, or url if there is no redirection
      def redirect_url(url, params={}, headers={}, redirect_limit=max_redirects)
        # parse the URL
        uri = URI.parse(url)
        # add URL parameters
        uri.query = URI.encode_www_form(params)

        # build the http object
        http = build_http(uri)
        # build the request
        request = Net::HTTP::Head.new(uri.request_uri, headers)

        # send the request
        response = http.request(request)
        # handle the response
        case response
        when Net::HTTPRedirection then
          if redirect_limit > 0
            url = response['location']
            head(response['location'], params, headers, redirect_limit - 1)
          end
        end
        url
      end


      # Encode URI components
      #
      # @param parameter [String] parameter value to encode
      # @return [String] URL encoded parameter value
      def encode(parameter)
        ERB::Util.url_encode parameter
      end

      # Determines the mime-type of a file
      # 
      # @param file [File | String] file or filename to detect
      # @return [Array] MIME::Type of the file
      def mimetype(file)
        mime_type = MIME::Types.type_for(file.class == File ? File.basename(file) : file)
        if mime_type.size == 0
          mime_type = MIME::Types['text/plain'] 
        end
        mime_type
      end

      # The maximum number of times to follow redirects.
      #
      # Can be passed in as an option when initializing the SDK
      # with either the @options[:max_redirects] or @options['max_redirects']
      # key.
      #
      # Expects an integer [Fixnum] value. Setting to 0 will disable redirects.
      #
      # @return [Fixnum] default 5
      def max_redirects
        limit = @options &&
        (
          @options[:max_redirects] ||
          @options['max_redirects']
        )
        limit.nil? ? 5 : limit.to_i
      end

      private

      # Build the Net::HTTP object.
      #
      # @param uri [URI] the URI for the HTTP request
      # @return [Net::HTTP]
      def build_http(uri)
        http = Net::HTTP.new(uri.host, uri.port)
        if (uri.scheme == 'https')
          http.use_ssl = true
          if (@options[:ssl_verify_mode].to_s.strip.downcase == 'peer')
            http.verify_mode = OpenSSL::SSL::VERIFY_PEER
            http.ca_file = @options[:ssl_ca_file] if @options[:ssl_ca_file]
          else
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          end
        end
        http.read_timeout=60
        http.open_timeout=60
        http
      end

    end


    # The Http class provides functionality to make generic HTTP requests.
    class Http

      include Kinetic::Platform::HttpUtils

      # The username used in the Basic Authentication header
      attr_reader :username
      # The password used in the Basic Authentication header
      attr_reader :password

      # Constructor
      #
      # @param username [String] username for Basic Authentication
      # @param password [String] password for Basic Authentication
      def initialize(username=nil, password=nil)
        @username = username
        @password = password
        @options = {}
      end

    end
    

  end
end
