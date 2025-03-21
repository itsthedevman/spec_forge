# frozen_string_literal: true

module SpecForge
  module HTTP
    #
    # HTTP client that executes requests and returns responses
    #
    # This class serves as a mediator between the test expectations
    # and the actual HTTP backend implementation.
    #
    # @example Basic usage
    #   client = HTTP::Client.new(base_url: "https://api.example.com")
    #   response = client.call(request)
    #
    class Client
      #
      # Creates a new HTTP client with configured backend
      #
      # @return [Client] A new HTTP client instance
      #
      def initialize(**)
        @backend = Backend.new(HTTP::Request.new(**))
      end

      #
      # Executes an HTTP request and returns the response
      #
      # @param request [HTTP::Request] The request to execute
      #
      # @return [Faraday::Response] The HTTP response
      #
      def call(request)
        @backend.public_send(
          request.http_verb.to_s.downcase,
          request.url,
          headers: request.headers.resolved,
          query: request.query.resolved,
          body: request.body.resolved
        )
      end
    end
  end
end
