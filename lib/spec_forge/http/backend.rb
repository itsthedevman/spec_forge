# frozen_string_literal: true

module SpecForge
  module HTTP
    class Backend
      CURLY_PLACEHOLDER = /\{(\w+)\}/
      COLON_PLACEHOLDER = /:(\w+)/

      attr_reader :connection

      #
      # Configures Faraday with the config values
      #
      # @param request [HTTP::Request]
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
            builder.headers.merge!(request.headers.resolve)

            # Params
            builder.params.merge!(request.query.resolve)
          end
      end

      #
      # Executes a DELETE request to <base_url>/<provided_url>
      #
      # @param url [String] The URL path to DELETE
      # @param query [Hash] Any query attributes to send
      # @param body [Hash]  Any body data to send
      #
      # @return [Hash] The response
      #
      def delete(url, query: {}, body: {})
        url = normalize_url(url, query)
        connection.delete(url) { |request| update_request(request, query, body) }
      end

      #
      # Executes a GET request to <base_url>/<provided_url>
      #
      # @param url [String] The URL path to GET
      # @param query [Hash] Any query attributes to send
      # @param body [Hash]  Any body data to send
      #
      # @return [Hash] The response
      #
      def get(url, query: {}, body: {})
        url = normalize_url(url, query)
        connection.get(url) { |request| update_request(request, query, body) }
      end

      #
      # Executes a PATCH request to <base_url>/<provided_url>
      #
      # @param url [String] The URL path to PATCH
      # @param query [Hash] Any query attributes to send
      # @param body [Hash]  Any body data to send
      #
      # @return [Hash] The response
      #
      def patch(url, query: {}, body: {})
        url = normalize_url(url, query)
        connection.patch(url) { |request| update_request(request, query, body) }
      end

      #
      # Executes a POST request to <base_url>/<provided_url>
      #
      # @param url [String] The URL path to POST
      # @param query [Hash] Any query attributes to send
      # @param body [Hash]  Any body data to send
      #
      # @return [Hash] The response
      #
      def post(url, query: {}, body: {})
        url = normalize_url(url, query)
        connection.post(url) { |request| update_request(request, query, body) }
      end

      #
      # Executes a PUT request to <base_url>/<provided_url>
      #
      # @param url [String] The URL path to PUT
      # @param query [Hash] Any query attributes to send
      # @param body [Hash]  Any body data to send
      #
      # @return [Hash] The response
      #
      def put(url, query: {}, body: {})
        url = normalize_url(url, query)
        connection.put(url) { |request| update_request(request, query, body) }
      end

      private

      def update_request(request, query, body)
        request.params.merge!(query)
        request.body = body.to_json
      end

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
