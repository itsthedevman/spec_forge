# frozen_string_literal: true

module SpecForge
  module HTTP
    attributes = [:base_url, :url, :http_method, :content_type, :query, :body, :authorization]

    class Request < Data.define(*attributes)
      #
      # Initializes a new Request instance with the given options
      #
      # @param [Hash] options The options to create the Request with
      #
      # @option options [String] :path The request URL (alias for :url)
      # @option options [String] :url The request URL
      #
      # @option options [String, Verb] :method The HTTP method to use (alias for :http_method)
      # @option options [String, Verb] :http_method The HTTP method to use
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
        base_url = extract_base_url(options)
        url = extract_url(options)
        content_type = normalize_content_type(options)
        http_method = normalize_http_method(options)
        query = Attribute::Resolvable.new(normalize_query(options))
        body = Attribute::Resolvable.new(normalize_body(content_type, options))
        authorization = extract_authorization(options)

        super(base_url:, url:, http_method:, content_type:, query:, body:, authorization:)
      end

      def http_verb
        http_method.name.downcase
      end

      private

      def extract_base_url(options)
        options[:base_url].presence || SpecForge.config.base_url
      end

      def extract_url(options)
        options[:path] || options[:url]
      end

      def normalize_http_method(options)
        method = options[:method] || options[:http_method] || "GET"

        if method.is_a?(String)
          Verb.from(method)
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

        Attribute.transform_hash_values(query, options[:variables])
      end

      def normalize_body(content_type, options)
        body = options[:body] || options[:data] || {}

        case content_type
        when "application/json"
          validate_and_transform_hash(body, options[:variables])
        end
      end

      def extract_authorization(options)
        SpecForge.config.authorization[:default]
      end

      def validate_and_transform_hash(hash, variables)
        raise InvalidTypeError.new(hash, Hash, for: "'body'") unless hash.is_a?(Hash)

        Attribute.transform_hash_values(hash, variables)
      end
    end
  end
end
