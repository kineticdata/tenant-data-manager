module Kinetic
  module Platform

    # The HttpResponse object normalizes the Net::HTTPResponse object
    # properties so they are always consistent.
    #
    # If the object passed in the constructor is a StandardError, the status code is
    # set to 0, and the {#exception} and {#backtrace} methods can be used to get the 
    # details.
    #
    # Regardless of whether a Net::HTTPResponse object or a StandardError object was 
    # passed in the constructor, the {#code} and {#message} methods will give information
    # about the response.
    class HttpResponse
      # response code [String] - always '0' if constructor object is a StandardError
      attr_reader :code
      # the parsed JSON response body if content-type is application/json
      attr_accessor :content
      # the raw response body string
      attr_accessor :content_string
      # the response content-type
      attr_reader :content_type
      # the resonse headers
      attr_reader :headers
      # response status message
      attr_reader :message
      # the raw response object
      attr_reader :response
      # response code [Fixnum] - always 0 if constructor object is a StandardError
      attr_reader :status
      
      # the StandardError backtrace if constructor object is a StandardError
      attr_reader :backtrace
      # the raw StandardError if constructor object is a StandardError
      attr_reader :exception

      # Constructor
      #
      # @param object [Net::HTTPResponse | StandardError] either a Net::HTTPResponse or a StandardError
      def initialize(object)
        case object
        when Net::HTTPResponse then
          @code = object.code
          @content_string = object.body
          @content_type = object.content_type
          @headers = object.each_header.inject({}) { |h,(k,v)| h[k] = v; h }
          @message = object.message
          @response = object
          @status = @code.to_i

          # if content type is json, try to parse the content string
          @content = case @content_type
            when "application/json" then
              # will raise an exception if content_string is not valid json
              JSON.parse(@content_string)
            else
              {}
            end
        when StandardError then
          @code = "0"
          @content = {}
          @content_string = nil
          @content_type = nil
          @backtrace = object.backtrace
          @exception = object.exception
          @message = object.message
          @status = @code.to_i
        else
          raise StandardError.new("Invalid response object: #{object.class}")
        end
      end
    end

  end
end