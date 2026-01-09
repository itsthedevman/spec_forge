# frozen_string_literal: true

module SpecForge
  module HTTP
    #
    # High-level HTTP client for executing requests
    #
    # Client wraps Backend and provides a simple interface for executing
    # HTTP::Request objects and returning responses.
    #
    class Client
      #
      # Creates a new HTTP client with a backend
      #
      # @return [Client] A new client instance
      #
      def initialize
        @backend = Backend.new
      end

      #
      # Executes an HTTP request and returns the response
      #
      # @param request [HTTP::Request] The request to execute
      #
      # @return [Faraday::Response] The HTTP response
      #
      def perform(request)
        @backend.public_send(
          request.http_verb.downcase,
          base_url: request.base_url,
          url: request.url.delete_prefix("/"),
          headers: request.headers,
          query: request.query,
          body: request.body
        )
      end
    end
  end
end
