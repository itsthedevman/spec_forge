# frozen_string_literal: true

module SpecForge
  module HTTP
    #
    # Low-level HTTP client wrapper around Faraday
    #
    # Backend provides methods for each HTTP verb and handles the actual
    # communication with the server. It's used internally by HTTP::Client.
    #
    class Backend
      #
      # The configured Faraday connection
      #
      # @return [Faraday::Connection]
      #
      attr_reader :connection

      #
      # Creates a new HTTP backend with a Faraday connection
      #
      # @return [Backend] A new backend instance
      #
      def initialize
        @connection = Faraday.new
      end

      #
      # Executes a DELETE request to <base_url>/<provided_url>
      #
      # @option options [String] :url The URL path to DELETE
      # @option options [String] :base_url The base URL to use for the request
      # @option options [Hash] :headers HTTP headers to add
      # @option options [Hash] :query Any query parameters to send
      # @option options [Hash] :body Any body data to send
      #
      # @return [Faraday::Response] The HTTP response
      #
      def delete(**)
        run_http_method(:delete, **)
      end

      #
      # Executes a GET request to <base_url>/<provided_url>
      #
      # @option options [String] :url The URL path to GET
      # @option options [String] :base_url The base URL to use for the request
      # @option options [Hash] :headers HTTP headers to add
      # @option options [Hash] :query Any query parameters to send
      # @option options [Hash] :body Any body data to send
      #
      # @return [Faraday::Response] The HTTP response
      #
      def get(**)
        run_http_method(:get, **)
      end

      #
      # Executes a PATCH request to <base_url>/<provided_url>
      #
      # @option options [String] :url The URL path to PATCH
      # @option options [String] :base_url The base URL to use for the request
      # @option options [Hash] :headers HTTP headers to add
      # @option options [Hash] :query Any query parameters to send
      # @option options [Hash] :body Any body data to send
      #
      # @return [Faraday::Response] The HTTP response
      #
      def patch(**)
        run_http_method(:patch, **)
      end

      #
      # Executes a POST request to <base_url>/<provided_url>
      #
      # @option options [String] :url The URL path to POST
      # @option options [String] :base_url The base URL to use for the request
      # @option options [Hash] :headers HTTP headers to add
      # @option options [Hash] :query Any query parameters to send
      # @option options [Hash] :body Any body data to send
      #
      # @return [Faraday::Response] The HTTP response
      #
      def post(**)
        run_http_method(:post, **)
      end

      #
      # Executes a PUT request to <base_url>/<provided_url>
      #
      # @option options [String] :url The URL path to PUT
      # @option options [String] :base_url The base URL to use for the request
      # @option options [Hash] :headers HTTP headers to add
      # @option options [Hash] :query Any query parameters to send
      # @option options [Hash] :body Any body data to send
      #
      # @return [Faraday::Response] The HTTP response
      #
      def put(**)
        run_http_method(:put, **)
      end

      private

      def run_http_method(method, url:, base_url:, headers: {}, query: {}, body: {})
        connection.url_prefix = base_url

        connection.public_send(method, url) do |request|
          request.headers.merge!(headers)
          request.headers.transform_values!(&:to_s)

          request.params.merge!(query)
          request.body = body
        end
      end
    end
  end
end
