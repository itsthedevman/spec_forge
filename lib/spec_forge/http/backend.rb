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

      #
      # Configures a new Faraday connection based on the request configuration
      #
      # @param request [HTTP::Request] The request configuration to use
      #
      # @return [Backend] A new backend instance with a configured connection
      #
      def initialize(base_url:)
        @connection = Faraday.new(url: base_url)
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
      def delete(url, **)
        run_http_method(:delete, url, **)
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
      def get(url, **)
        run_http_method(:get, url, **)
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
      def patch(url, **)
        run_http_method(:patch, url, **)
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
      def post(url, **)
        run_http_method(:post, url, **)
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
      def put(url, **)
        run_http_method(:put, url, **)
      end

      private

      def run_http_method(method, url, base_url: nil, headers: {}, query: {}, body: {})
        # Allow switching out the base_url before the request is sent
        if base_url
          previous_url = connection.url_prefix
          connection.url_prefix = base_url
        end

        connection.public_send(method, url) do |request|
          request.headers.merge!(headers)
          request.headers.transform_values!(&:to_s)

          request.params.merge!(query)
          request.body = body.to_json
        end

        # Reset the base_url after the request is sent
        connection.url_prefix = previous_url if base_url
      end
    end
  end
end
