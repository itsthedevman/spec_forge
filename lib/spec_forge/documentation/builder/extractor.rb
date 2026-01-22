# frozen_string_literal: true

module SpecForge
  module Documentation
    class Builder
      #
      # Extracts endpoint data from a test execution context
      #
      # The Extractor takes a Forge::Context from a completed test step
      # and extracts all relevant request and response data needed for
      # API documentation generation.
      #
      # @example Extracting endpoint data
      #   extractor = Extractor.new(context)
      #   endpoint = extractor.extract_endpoint
      #   # => { url: "/users", http_verb: "GET", response_status: 200, ... }
      #
      class Extractor
        #
        # Creates a new Extractor instance
        #
        # @param context [Forge::Context] The execution context from a test step
        #   containing request/response variables
        #
        # @return [Extractor] A new extractor instance
        #
        def initialize(context)
          @context = context
          @step = context.step
          @variables = context.variables
        end

        #
        # Extracts endpoint data from the context
        #
        # Pulls request and response information from the context variables
        # and organizes it into a hash structure for documentation.
        #
        # @return [Hash] Endpoint data containing:
        #   - :base_url [String] The API base URL
        #   - :url [String] The endpoint path
        #   - :http_verb [String] The HTTP method (GET, POST, etc.)
        #   - :content_type [String, nil] The request content type
        #   - :request_body [Hash] The request body
        #   - :request_headers [Hash] Request headers (excluding content-type)
        #   - :request_query [Hash] Query parameters
        #   - :response_status [Integer] HTTP response status code
        #   - :response_body [Hash, Array, String] The response body
        #   - :response_headers [Hash] Response headers
        #
        def extract_endpoint
          request = @variables[:request]
          response = @variables[:response]
          headers = request[:headers]

          {
            # Request data
            base_url: request[:base_url],
            url: request[:url],
            http_verb: request[:http_verb],
            content_type: headers["content-type"],
            request_body: request[:body],
            request_headers: headers.except("content-type"),
            request_query: request[:query],

            # Response data
            response_status: response[:status],
            response_body: response[:body],
            response_headers: response[:headers]
          }
        end
      end
    end
  end
end
