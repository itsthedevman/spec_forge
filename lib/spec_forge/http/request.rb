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
