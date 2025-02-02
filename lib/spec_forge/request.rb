# frozen_string_literal: true

module SpecForge
  class Request < Data.define(:url, :http_method, :content_type, :query, :body)
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
    # @option options [Hash] :data The request body (alias for :body)
    # @option options [Hash] :body The request body (defaults to {})
    #
    def initialize(**options)
      url = extract_url(options)
      content_type = normalize_content_type(options)
      http_method = normalize_http_method(options)
      query = normalize_query(options)
      body = normalize_body(content_type, options)

      super(url:, http_method:, content_type:, query:, body:)
    end

    def call
      HTTPClient.new(self).call
    end

    def update_from_expectation(**input)
      query = normalize_query(input)
      body = normalize_body(content_type, input)

      with(query:, body:)
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
      query = options[:query] || options[:params] || {}
      raise InvalidTypeError.new(query, Hash, for: "'query'") unless query.is_a?(Hash)

      query.transform_values { |v| Attribute.from(v) }
    end

    def normalize_body(content_type, options)
      body = options[:body] || options[:data] || {}

      case content_type
      when "application/json"
        validate_and_transform_hash(body)
      end
    end

    def validate_and_transform_hash(hash)
      raise InvalidTypeError.new(hash, Hash, for: "'body'") unless hash.is_a?(Hash)

      hash.transform_values { |v| Attribute.from(v) }
    end
  end
end
