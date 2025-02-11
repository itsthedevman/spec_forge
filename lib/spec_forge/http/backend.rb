# frozen_string_literal: true

module SpecForge
  module HTTP
    class Backend
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
            builder.headers.merge!(request.headers)

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
        connection.put(url) { |request| update_request(request, query, body) }
      end

      private

      def update_request(request, query, body)
        request.params.merge!(query)
        request.body = body.to_json
      end
    end
  end
end
