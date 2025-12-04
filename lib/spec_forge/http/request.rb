# frozen_string_literal: true

module SpecForge
  module HTTP
    #
    # The attributes used to build a Request
    #
    # @return [Array<Symbol>]
    #
    REQUEST_ATTRIBUTES = %i[
      base_url
      url
      http_verb
      content_type
      headers
      query
      body
    ].freeze

    #
    # Represents an HTTP request configuration
    #
    # This data object contains all the necessary information to construct
    # an HTTP request, including URL, method, headers, query params, and body.
    #
    # @example Creating a request
    #   request = HTTP::Request.new(
    #     base_url: "https://api.example.com",
    #     url: "/users",
    #     http_verb: "GET",
    #     headers: {"Content-Type" => "application/json"},
    #     query: {page: 1},
    #     body: {}
    #   )
    #
    class Request < Data.define(*REQUEST_ATTRIBUTES)
      #
      # Regex that attempts to match a valid header
      #
      # @return [Regexp]
      #
      HEADER = /^[A-Z][A-Za-z0-9!-]*$/

      #
      # Creates a new Request with standardized headers and values
      #
      # @param base_url [String, nil] The base URL for the request
      # @param url [String, nil] The path portion of the URL
      # @param http_verb [String, Symbol, nil] The HTTP method (GET, POST, etc.)
      # @param headers [Hash, nil] HTTP headers for the request
      # @param query [Hash, nil] Query parameters to include
      # @param body [Hash, nil] Request body data
      #
      # @return [Request] A new immutable request object
      #
      def initialize(**options)
        base_url = options[:base_url] || ""
        url = options[:url] || ""
        http_verb = Verb.from(options[:http_verb].presence || "GET")
        query = Attribute.from(options[:query] || {})
        body = Attribute.from(options[:body] || {})
        headers = normalize_headers(options[:headers] || {})
        content_type = options[:content_type]

        super(base_url:, url:, http_verb:, content_type:, headers:, query:, body:)
      end

      #
      # Returns a hash representation with all attributes fully resolved
      #
      # @return [Hash] The request data with all dynamic values resolved
      #
      def to_h
        hash = super.transform_values { |v| v.respond_to?(:resolved) ? v.resolved : v }
        hash[:http_verb] = hash[:http_verb].to_s
        hash
      end

      private

      #
      # Normalizes HTTP header keys to standard format
      #
      # Converts snake_case and other formats to HTTP Header-Case format
      # Examples:
      #   content_type -> Content-Type
      #   api_key -> Api-Key
      #
      # @param headers [Hash] The headers to normalize
      #
      # @return [Attribute::ResolvableHash] Normalized headers as attributes
      #
      # @private
      #
      def normalize_headers(headers)
        headers =
          headers.transform_keys do |key|
            key = key.to_s

            # If the key is already like a header, don't change it
            if key.match?(HEADER)
              key
            else
              # content_type => Content-Type
              key.downcase.titleize.gsub(/\s+/, "-")
            end
          end

        Attribute.from(headers)
      end
    end
  end
end
