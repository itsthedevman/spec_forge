# frozen_string_literal: true

module SpecForge
  module HTTP
    #
    # Represents an HTTP request with all its components
    #
    # Request is a value object that holds the URL, method, headers,
    # query parameters, and body for an HTTP request.
    #
    class Request < Struct.new(:base_url, :url, :http_verb, :headers, :query, :body)
      #
      # Creates a new HTTP request with the specified options
      #
      # @param options [Hash] Request options
      # @option options [String] :base_url The base URL for the request
      # @option options [String] :url The URL path for the request
      # @option options [String] :http_verb The HTTP method (defaults to "GET")
      # @option options [Hash] :headers HTTP headers
      # @option options [Hash] :query Query parameters
      # @option options [Hash, String] :body Request body
      #
      # @return [Request] A new request instance
      #
      def initialize(**options)
        super(
          base_url: options[:base_url] || "",
          url: options[:url] || "",
          http_verb: Verb.from(options[:http_verb].presence || "GET"),
          headers: options[:headers] || {},
          query: options[:query] || {},
          body: options[:body] || {}
        )
      end

      #
      # Returns the Content-Type header value
      #
      # @return [String, nil] The content type or nil if not set
      #
      def content_type
        headers["content-type"]
      end

      #
      # Returns whether this request has a JSON content type
      #
      # @return [Boolean] True if content type is application/json
      #
      def json?
        content_type == "application/json"
      end

      #
      # Converts the request to a hash with stringified verb
      #
      # @return [Hash] Hash representation of the request
      #
      def to_h
        super.tap do |h|
          h[:http_verb] = h[:http_verb].to_s
        end
      end
    end
  end
end
