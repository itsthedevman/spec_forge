# frozen_string_literal: true

module SpecForge
  class Request < Data.define(:url, :http_method, :content_type, :query, :body)
    CONTENT_TYPES = {
      "application/json" => ->(body) { validate_and_transform_hash(body) },
      "text/plain" => ->(body) { Attribute.from(body.to_s) }
    }.freeze

    class << self
      def normalize_body(content_type, body)
        transformer = CONTENT_TYPES[content_type.to_s]
        raise ArgumentError, "Unsupported content type: #{content_type}" if transformer.nil?

        transformer.call(body)
      end

      private

      def validate_and_transform_hash(body)
        raise InvalidTypeError.new(body, Hash, for: "'body'") unless body.is_a?(Hash)

        body.transform_values { |v| Attribute.from(v) }
      end
    end

    #
    # Initializes a new Request instance with the given options
    #
    # @param [Hash] options The options to create the Request with
    #
    # @option options [String] :path The request URL (alias for :url)
    # @option options [String] :url The request URL
    #
    # @option options [String, HTTPMethod] :method The HTTP method to use (alias for :http_method)
    # @option options [String, HTTPMethod] :http_method The HTTP method to use
    #
    # @option options [String] :content_type
    #  The content type for the request (defaults to "application/json")
    #
    # @option options [Hash] :params The query parameters for the request (alias for :query)
    # @option options [Hash] :query The query parameters for the request (defaults to {})
    #
    # @option options [Hash, String] :body The request body (defaults to {})
    #
    def initialize(**options)
      super(
        url: extract_url(options),
        http_method: normalize_http_method(options),
        content_type: normalize_content_type(options),
        query: normalize_query(options),
        body: self.class.normalize_body(
          options[:content_type] || "application/json",
          options[:body] || {}
        )
      )
    end

    alias_method :path, :url
    alias_method :params, :query

    def update(body, params)
      with(
        body: self.body.merge(body),
        query: query.merge(params)
      )
    end

    def call
      HTTPClient.new(self).call
    end

    private

    def extract_url(options)
      options[:path] || options[:url]
    end

    def normalize_http_method(options)
      method = options[:method] || options[:http_method] || "GET"

      if method.is_a?(String)
        HTTPMethod.from(method)
      else
        method
      end
    end

    def normalize_content_type(options)
      type = options[:content_type] || "application/json"
      mime_type = MIME::Types[type].first
      return mime_type if mime_type

      raise ArgumentError, "Invalid content type: #{type.inspect}"
    end

    def normalize_query(options)
      params = options[:query] || options[:params] || {}
      raise InvalidTypeError.new(params, Hash, for: "'query'") unless params.is_a?(Hash)

      params.transform_values { |v| Attribute.from(v) }
    end
  end
end
