require 'base64'
require 'erb'
require 'net/https'
require 'uri'

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
      # @param http_options [Hash] hash of http options
      # @option http_options [Fixnum] :max_redirects optional - max number of times to redirect
      # @option http_options [Fixnum] :gateway_retry_limit optional - max number of times to retry a bad gateway
      # @option http_options [Float] :gateway_retry_delay optional - number of seconds to delay before retrying a bad gateway
      # @return [Kinetic::Platform::HttpResponse] response
      def get(url, params={}, headers={}, http_options={})
        # determine the http options
        redirect_limit = http_options[:max_redirects] || max_redirects
        gateway_retries = http_options[:gateway_retry_limit] || gateway_retry_limit
        gateway_delay = http_options[:gateway_retry_delay] || gateway_retry_delay

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
          # handle 302
          when Net::HTTPRedirection then
            if redirect_limit == -1
              HttpResponse.new(response)
            elsif redirect_limit == 0
              raise Net::HTTPFatalError.new("Too many redirects", response)
            else
              get(response['location'], params, headers, http_options.merge({
                :max_redirects => redirect_limit - 1
              }))
            end
          # handle 502, 503, 504
          when Net::HTTPBadGateway, Net::HTTPServiceUnavailable, Net::HTTPGatewayTimeOut then
            if gateway_retries == -1
              HttpResponse.new(response)
            elsif gateway_retries == 0
              Kinetic::Platform.logger.info("HTTP response: #{response.code} #{response.message}")
              raise Net::HTTPFatalError.new("#{response.code} #{response.message}", response)
            else
              Kinetic::Platform.logger.info("#{response.code} #{response.message}, retrying in #{gateway_delay} seconds")
              sleep(gateway_delay)
              get(url, params, headers, http_options.merge({
                :gateway_retry_limit => gateway_retries - 1
              }))
            end
          when Net::HTTPUnknownResponse, NilClass then
            Kinetic::Platform.logger.info("HTTP response code: 0")
            e = Net::HTTPFatalError.new("Unknown response from server", response)
            HttpResponse.new(e)
          else
            Kinetic::Platform.logger.info("HTTP response code: #{response.code}")
            HttpResponse.new(response)
          end
        rescue Net::HTTPBadResponse => e
          Kinetic::Platform.logger.info("HTTP bad response: #{e.inspect}")
          HttpResponse.new(e)
        rescue StandardError => e
          Kinetic::Platform.logger.info("HTTP error: #{e.inspect}")
          HttpResponse.new(e)
        end
      end

      # Send an HTTP POST request
      # 
      # @param url [String] url to send the request to
      # @param data [Hash] the payload to send with the request
      # @param headers [Hash] hash of headers to send
      # @param http_options [Hash] hash of http options
      # @option http_options [Fixnum] :max_redirects optional - max number of times to redirect
      # @option http_options [Fixnum] :gateway_retry_limit optional - max number of times to retry a bad gateway
      # @option http_options [Float] :gateway_retry_delay optional - number of seconds to delay before retrying a bad gateway
      # @return [Kinetic::Platform::HttpResponse] response
      def post(url, data={}, headers={}, http_options={})
        # determine the http options
        redirect_limit = http_options[:max_redirects] || max_redirects
        gateway_retries = http_options[:gateway_retry_limit] || gateway_retry_limit
        gateway_delay = http_options[:gateway_retry_delay] || gateway_retry_delay

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
          # handle 302
          when Net::HTTPRedirection then
            if redirect_limit == -1
              HttpResponse.new(response)
            elsif redirect_limit == 0
              raise Net::HTTPFatalError.new("Too many redirects", response)
            else
              post(response['location'], data, headers, http_options.merge({
                :max_redirects => redirect_limit - 1
              }))
            end
          # handle 502, 503, 504
          when Net::HTTPBadGateway, Net::HTTPServiceUnavailable, Net::HTTPGatewayTimeOut then
            if gateway_retries == -1
              HttpResponse.new(response)
            elsif gateway_retries == 0
              Kinetic::Platform.logger.info("HTTP response: #{response.code} #{response.message}")
              raise Net::HTTPFatalError.new("#{response.code} #{response.message}", response)
            else
              Kinetic::Platform.logger.info("#{response.code} #{response.message}, retrying in #{gateway_delay} seconds")
              sleep(gateway_delay)
              post(url, data, headers, http_options.merge({
                :gateway_retry_limit => gateway_retries - 1
              }))
            end
          when Net::HTTPUnknownResponse, NilClass then
            Kinetic::Platform.logger.info("HTTP response code: 0")
            e = Net::HTTPFatalError.new("Unknown response from server", response)
            HttpResponse.new(e)
          else
            Kinetic::Platform.logger.info("HTTP response code: #{response.code}")
            HttpResponse.new(response)
          end
        rescue Net::HTTPBadResponse => e
          Kinetic::Platform.logger.info("HTTP bad response: #{e.inspect}")
          HttpResponse.new(e)
        rescue StandardError => e
          Kinetic::Platform.logger.info("HTTP error: #{e.inspect}")
          HttpResponse.new(e)
        end
      end

      # Send an HTTP PUT request
      # 
      # @param url [String] url to send the request to
      # @param data [Hash] payload to send with the request
      # @param headers [Hash] hash of headers to send
      # @param http_options [Hash] hash of http options
      # @option http_options [Fixnum] :max_redirects optional - max number of times to redirect
      # @option http_options [Fixnum] :gateway_retry_limit optional - max number of times to retry a bad gateway
      # @option http_options [Float] :gateway_retry_delay optional - number of seconds to delay before retrying a bad gateway
      # @return [Kinetic::Platform::HttpResponse] response
      def put(url, data={}, headers={}, http_options={})
        # determine the http options
        redirect_limit = http_options[:max_redirects] || max_redirects
        gateway_retries = http_options[:gateway_retry_limit] || gateway_retry_limit
        gateway_delay = http_options[:gateway_retry_delay] || gateway_retry_delay

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
          # handle 302
          when Net::HTTPRedirection then
            if redirect_limit == -1
              HttpResponse.new(response)
            elsif redirect_limit == 0
              raise Net::HTTPFatalError.new("Too many redirects", response)
            else
              put(response['location'], data, headers, http_options.merge({
                :max_redirects => redirect_limit - 1
              }))
            end
          # handle 502, 503, 504
          when Net::HTTPBadGateway, Net::HTTPServiceUnavailable, Net::HTTPGatewayTimeOut then
            if gateway_retries == -1
              HttpResponse.new(response)
            elsif gateway_retries == 0
              Kinetic::Platform.logger.info("HTTP response: #{response.code} #{response.message}")
              raise Net::HTTPFatalError.new("#{response.code} #{response.message}", response)
            else
              Kinetic::Platform.logger.info("#{response.code} #{response.message}, retrying in #{gateway_delay} seconds")
              sleep(gateway_delay)
              put(url, data, headers, http_options.merge({
                :gateway_retry_limit => gateway_retries - 1
              }))
            end
          when Net::HTTPUnknownResponse, NilClass then
            Kinetic::Platform.logger.info("HTTP response code: 0")
            e = Net::HTTPFatalError.new("Unknown response from server", response)
            HttpResponse.new(e)
          else
            Kinetic::Platform.logger.info("HTTP response code: #{response.code}")
            HttpResponse.new(response)
          end
        rescue Net::HTTPBadResponse => e
          Kinetic::Platform.logger.info("HTTP bad response: #{e.inspect}")
          HttpResponse.new(e)
        rescue StandardError => e
          Kinetic::Platform.logger.info("HTTP error: #{e.inspect}")
          HttpResponse.new(e)
        end
      end

      # Send an HTTP DELETE request
      # 
      # @param url [String] url to send the request to
      # @param headers [Hash] hash of headers to send
      # @param http_options [Hash] hash of http options
      # @option http_options [Fixnum] :max_redirects optional - max number of times to redirect
      # @option http_options [Fixnum] :gateway_retry_limit optional - max number of times to retry a bad gateway
      # @option http_options [Float] :gateway_retry_delay optional - number of seconds to delay before retrying a bad gateway
      # @return [Kinetic::Platform::HttpResponse] response
      def delete(url, headers={}, http_options={})
        # determine the http options
        redirect_limit = http_options[:max_redirects] || max_redirects
        gateway_retries = http_options[:gateway_retry_limit] || gateway_retry_limit
        gateway_delay = http_options[:gateway_retry_delay] || gateway_retry_delay

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
          # handle 302
          when Net::HTTPRedirection then
            if redirect_limit == -1
              HttpResponse.new(response)
            elsif redirect_limit == 0
              raise Net::HTTPFatalError.new("Too many redirects", response)
            else
              delete(response['location'], headers, http_options.merge({
                :max_redirects => redirect_limit - 1
              }))
            end
          # handle 502, 503, 504
          when Net::HTTPBadGateway, Net::HTTPServiceUnavailable, Net::HTTPGatewayTimeOut then
            if gateway_retries == -1
              HttpResponse.new(response)
            elsif gateway_retries == 0
              Kinetic::Platform.logger.info("HTTP response: #{response.code} #{response.message}")
              raise Net::HTTPFatalError.new("#{response.code} #{response.message}", response)
            else
              Kinetic::Platform.logger.info("#{response.code} #{response.message}, retrying in #{gateway_delay} seconds")
              sleep(gateway_delay)
              delete(url, headers, http_options.merge({
                :gateway_retry_limit => gateway_retries - 1
              }))
            end
          when Net::HTTPUnknownResponse, NilClass then
            Kinetic::Platform.logger.info("HTTP response code: 0")
            e = Net::HTTPFatalError.new("Unknown response from server", response)
            HttpResponse.new(e)
          else
            Kinetic::Platform.logger.info("HTTP response code: #{response.code}")
            HttpResponse.new(response)
          end
        rescue Net::HTTPBadResponse => e
          Kinetic::Platform.logger.info("HTTP bad response: #{e.inspect}")
          HttpResponse.new(e)
        rescue StandardError => e
          Kinetic::Platform.logger.info("HTTP error: #{e.inspect}")
          HttpResponse.new(e)
        end
      end

      # Send an HTTP HEAD request
      # 
      # @param url [String] url to send the request to
      # @param params [Hash] Query parameters that are added to the URL, such as +include+
      # @param headers [Hash] hash of headers to send
      # @param http_options [Hash] hash of http options
      # @option http_options [Fixnum] :max_redirects optional - max number of times to redirect
      # @option http_options [Fixnum] :gateway_retry_limit optional - max number of times to retry a bad gateway
      # @option http_options [Float] :gateway_retry_delay optional - number of seconds to delay before retrying a bad gateway
      # @return [Kinetic::Platform::HttpResponse] response
      def head(url, params={}, headers={}, http_options={})
        # determine the http options
        redirect_limit = http_options[:max_redirects] || max_redirects
        gateway_retries = http_options[:gateway_retry_limit] || gateway_retry_limit
        gateway_delay = http_options[:gateway_retry_delay] || gateway_retry_delay

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
          # handle 302
          when Net::HTTPRedirection then
            if redirect_limit == -1
              HttpResponse.new(response)
            elsif redirect_limit == 0
              raise Net::HTTPFatalError.new("Too many redirects", response)
            else
              head(response['location'], params, headers, http_options.merge({
                :max_redirects => redirect_limit - 1
              }))
            end
          # handle 502, 503, 504
          when Net::HTTPBadGateway, Net::HTTPServiceUnavailable, Net::HTTPGatewayTimeOut then
            if gateway_retries == -1
              HttpResponse.new(response)
            elsif gateway_retries == 0
              Kinetic::Platform.logger.info("HTTP response: #{response.code} #{response.message}")
              raise Net::HTTPFatalError.new("#{response.code} #{response.message}", response)
            else
              Kinetic::Platform.logger.info("#{response.code} #{response.message}, retrying in #{gateway_delay} seconds")
              sleep(gateway_delay)
              head(url, params, headers, http_options.merge({
                :gateway_retry_limit => gateway_retries - 1
              }))
            end
          when Net::HTTPUnknownResponse, NilClass then
            Kinetic::Platform.logger.info("HTTP response code: 0")
            e = Net::HTTPFatalError.new("Unknown response from server", response)
            HttpResponse.new(e)
          else
            Kinetic::Platform.logger.info("HTTP response code: #{response.code}")
            HttpResponse.new(response)
          end
        rescue Net::HTTPBadResponse => e
          Kinetic::Platform.logger.info("HTTP bad response: #{e.inspect}")
          HttpResponse.new(e)
        rescue StandardError => e
          Kinetic::Platform.logger.info("HTTP error: #{e.inspect}")
          HttpResponse.new(e)
        end
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

      # The maximum number of times to retry on a bad gateway response.
      #
      # Can be passed in as an option when initializing the SDK
      # with either the @options[:gateway_retry_limit] or 
      # @options['gateway_retry_limit'] key.
      #
      # Expects an integer [Fixnum] value. Setting to -1 will disable retries on
      # a bad gateway response.
      #
      # @return [Fixnum] default -1
      def gateway_retry_limit
        limit = @options &&
        (
          @options[:gateway_retry_limit] ||
          @options['gateway_retry_limit']
        )
        limit.nil? ? -1 : limit.to_i
      end

      # The amount of time in seconds to delay before retrying the request when
      # a bad gateway response is encountered.
      #
      # Can be passed in as an option when initializing the SDK
      # with either the @options[:gateway_retry_delay] or 
      # @options['gateway_retry_delay'] key.
      #
      # Expects a double [Float] value.
      #
      # @return [Float] default 1.0
      def gateway_retry_delay
        delay = @options &&
        (
          @options[:gateway_retry_delay] ||
          @options['gateway_retry_delay']
        )
        delay.nil? ? 1.0 : delay.to_f
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
            http.ca_file = @options[:ssl_ca_file] if @options[:ssl_ca_file]
            http.verify_mode = OpenSSL::SSL::VERIFY_PEER
            OpenSSL.debug = @options[:log_level].to_s.strip.downcase == 'trace'
          else
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE
            OpenSSL.debug = false
          end
        end
        http.read_timeout = (@options[:read_timeout] || 60).to_i
        http.open_timeout = (@options[:open_timeout] || 60).to_i
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
      # @param http_options [Hash] hash of http options
      # @option http_options [String] :log_level (off) log_level
      # @option http_options [Fixnum] :max_redirects (5) max number of times to redirect
      # @option http_options [Fixnum] :gateway_retry_limit (-1) max number of times to retry a bad gateway
      # @option http_options [Float] :gateway_retry_delay (1.0) number of seconds to delay before retrying a bad gateway
      # @option http_options [String] :ssl_ca_file (/etc/ca.crt certificate) location of the ca certificate
      # @option http_options [String] :ssl_verify_mode (none) use `peer` to enable verification
      def initialize(username=nil, password=nil, http_options={})
        @username = username
        @password = password
        @options = http_options
      end

    end
    

  end
end
