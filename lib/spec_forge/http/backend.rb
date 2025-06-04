# frozen_string_literal: true

module SpecForge
  module HTTP
    #
    # Handles the low-level HTTP operations using Faraday
    #
    # This class is responsible for creating and configuring the Faraday connection,
    # executing the actual HTTP requests, and handling URL path parameter substitution.
    #
    # @example Basic usage
    #   backend = Backend.new(request)
    #   response = backend.get("/users")
    #
    class Backend
      #
      # Regular expression to match { placeholder } style URL parameters
      #
      # @return [Regexp]
      #
      CURLY_PLACEHOLDER = /\{(\w+)\}/

      #
      # Regular expression to match :placeholder style URL parameters
      #
      # @return [Regexp]
      #
      COLON_PLACEHOLDER = /:(\w+)/

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
      def initialize(request)
        @connection =
          Faraday.new(url: request.base_url) do |builder|
            # Content-Type
            if !request.headers.key?("Content-Type")
              builder.request :json
              builder.response :json
            end

            # Headers
            builder.headers.merge!(request.headers.resolved)
          end
      end

      #
      # Executes a DELETE request to <base_url>/<provided_url>
      #
      # @param url [String] The URL path to DELETE
      # @param headers [Hash] HTTP headers to add
      # @param query [Hash] Any query parameters to send
      # @param body [Hash] Any body data to send
      #
      # @return [Faraday::Response] The HTTP response
      #
      def delete(url, headers: {}, query: {}, body: {})
        url = normalize_url(url, query)
        connection.delete(url) { |request| update_request(request, headers, query, body) }
      end

      #
      # Executes a GET request to <base_url>/<provided_url>
      #
      # @param url [String] The URL path to GET
      # @param headers [Hash] HTTP headers to add
      # @param query [Hash] Any query parameters to send
      # @param body [Hash] Any body data to send
      #
      # @return [Faraday::Response] The HTTP response
      #
      def get(url, headers: {}, query: {}, body: {})
        url = normalize_url(url, query)
        connection.get(url) { |request| update_request(request, headers, query, body) }
      end

      #
      # Executes a PATCH request to <base_url>/<provided_url>
      #
      # @param url [String] The URL path to PATCH
      # @param headers [Hash] HTTP headers to add
      # @param query [Hash] Any query parameters to send
      # @param body [Hash] Any body data to send
      #
      # @return [Faraday::Response] The HTTP response
      #
      def patch(url, headers: {}, query: {}, body: {})
        url = normalize_url(url, query)
        connection.patch(url) { |request| update_request(request, headers, query, body) }
      end

      #
      # Executes a POST request to <base_url>/<provided_url>
      #
      # @param url [String] The URL path to POST
      # @param headers [Hash] HTTP headers to add
      # @param query [Hash] Any query parameters to send
      # @param body [Hash] Any body data to send
      #
      # @return [Faraday::Response] The HTTP response
      #
      def post(url, headers: {}, query: {}, body: {})
        url = normalize_url(url, query)
        connection.post(url) { |request| update_request(request, headers, query, body) }
      end

      #
      # Executes a PUT request to <base_url>/<provided_url>
      #
      # @param url [String] The URL path to PUT
      # @param headers [Hash] HTTP headers to add
      # @param query [Hash] Any query parameters to send
      # @param body [Hash] Any body data to send
      #
      # @return [Faraday::Response] The HTTP response
      #
      def put(url, headers: {}, query: {}, body: {})
        url = normalize_url(url, query)
        connection.put(url) { |request| update_request(request, headers, query, body) }
      end

      private

      #
      # Updates the request with query parameters and body
      #
      # @param request [Faraday::Request] The request to update
      # @param headers [Hash] HTTP headers to add
      # @param query [Hash] Query parameters to add
      # @param body [Hash] Body data to add
      #
      # @private
      #
      def update_request(request, headers, query, body)
        request.headers.merge!(headers)
        request.headers.transform_values!(&:to_s)

        request.params.merge!(query)
        request.body = body.to_json
      end

      #
      # Normalizes a URL by replacing path parameters with their values
      #
      # Handles both curly brace style {param} and colon style :param
      # Parameters are extracted from the query hash and removed after substitution
      #
      # @param url [String] The URL pattern with potential placeholders
      # @param query [Hash] Query parameters that may contain values for placeholders
      #
      # @return [String] The URL with placeholders replaced by actual values
      #
      # @raise [URI::InvalidURIError] If the resulting URL is invalid
      #
      # @private
      #
      def normalize_url(url, query)
        # /users/<user_id>
        url = replace_url_placeholder(url, query, CURLY_PLACEHOLDER)

        # /users/:user_id
        url = replace_url_placeholder(url, query, COLON_PLACEHOLDER)

        # Attempt to validate (the colon style is considered valid apparently)
        begin
          URI.parse(url)
        rescue URI::InvalidURIError
          raise URI::InvalidURIError,
            "#{url.inspect} is not a valid URI. If you're using path parameters (like ':id' or '{id}'), ensure they are defined in the 'query' section."
        end

        url
      end

      #
      # Replaces URL placeholders with values from the query hash
      #
      # @param url [String] The URL with placeholders
      # @param query [Hash] The query parameters containing values
      # @param regex [Regexp] The pattern to match (curly or colon style)
      #
      # @return [String] The URL with placeholders replaced
      #
      # @private
      #
      def replace_url_placeholder(url, query, regex)
        match = url.match(regex)
        return url if match.nil?

        key = match[1].to_sym
        return url unless query.key?(key)

        value = query.delete(key)
        url.gsub(
          match[0],
          URI.encode_uri_component(value.to_s)
        )
      end
    end
  end
end
