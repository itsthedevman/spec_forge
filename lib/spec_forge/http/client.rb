# frozen_string_literal: true

module SpecForge
  module HTTP
    class Client
      #
      # Creates a new HTTP client to middleman between the tests and the backend
      #
      # @param ** [Hash] Request attributes
      #
      def initialize(**)
        @adapter = Backend.new(request)
      end

      #
      # Triggers an HTTP request to the URL
      #
      # @return [Hash] The response
      #
      def call(request)
        @adapter.public_send(
          request.http_verb,
          request.url,
          query: request.query.resolve,
          body: request.body.resolve
        )
      end
    end
  end
end
