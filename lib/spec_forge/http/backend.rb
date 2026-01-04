# frozen_string_literal: true

module SpecForge
  module HTTP
    class Backend
      #
      # The configured Faraday connection
      #
      # @return [Faraday::Connection]
      #
      attr_reader :connection

      def initialize
        @connection = Faraday.new
      end

      #
      # Executes a DELETE request to <base_url>/<provided_url>
      #
      # @param url [String] The URL path to DELETE
      # @param base_url [String] The base URL to use for the request
      # @param headers [Hash] HTTP headers to add
      # @param query [Hash] Any query parameters to send
      # @param body [Hash] Any body data to send
      #
      # @return [Faraday::Response] The HTTP response
      #
      def delete(**)
        run_http_method(:delete, **)
      end

      #
      # Executes a GET request to <base_url>/<provided_url>
      #
      # @param url [String] The URL path to GET
      # @param base_url [String] The base URL to use for the request
      # @param headers [Hash] HTTP headers to add
      # @param query [Hash] Any query parameters to send
      # @param body [Hash] Any body data to send
      #
      # @return [Faraday::Response] The HTTP response
      #
      def get(**)
        run_http_method(:get, **)
      end

      #
      # Executes a PATCH request to <base_url>/<provided_url>
      #
      # @param url [String] The URL path to PATCH
      # @param base_url [String] The base URL to use for the request
      # @param headers [Hash] HTTP headers to add
      # @param query [Hash] Any query parameters to send
      # @param body [Hash] Any body data to send
      #
      # @return [Faraday::Response] The HTTP response
      #
      def patch(**)
        run_http_method(:patch, **)
      end

      #
      # Executes a POST request to <base_url>/<provided_url>
      #
      # @param url [String] The URL path to POST
      # @param base_url [String] The base URL to use for the request
      # @param headers [Hash] HTTP headers to add
      # @param query [Hash] Any query parameters to send
      # @param body [Hash] Any body data to send
      #
      # @return [Faraday::Response] The HTTP response
      #
      def post(**)
        run_http_method(:post, **)
      end

      #
      # Executes a PUT request to <base_url>/<provided_url>
      #
      # @param url [String] The URL path to PUT
      # @param base_url [String] The base URL to use for the request
      # @param headers [Hash] HTTP headers to add
      # @param query [Hash] Any query parameters to send
      # @param body [Hash] Any body data to send
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
