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
      # @option options [String] :url The request URL
      #
      # @option options [String, Verb] :http_method The HTTP method to use
      #
      # @option options [String] :content_type
      #  The content type for the request (defaults to "application/json")
      #
      # @option options [Hash] :query The query parameters for the request (defaults to {})
      #
      # @option options [Hash] :body The request body (defaults to {})
      #
      def initialize(**options)
        base_url = extract_base_url(options)
        url = extract_url(options)
        content_type = normalize_content_type(options)
        http_method = normalize_http_method(options)
        query = normalize_query(options)
        body = normalize_body(content_type, options)
        authorization = extract_authorization(options)

        super(base_url:, url:, http_method:, content_type:, query:, body:, authorization:)
      end

      def http_verb
        http_method.name.downcase
      end

      private

      def extract_base_url(options)
        options[:base_url]&.value&.presence || SpecForge.config.base_url
      end

      def extract_url(options)
        options[:url].value
      end

      def normalize_http_method(options)
        method = options[:http_method].value

        if method.is_a?(String)
          Verb.from(method)
        else
          method
        end
      end

      def normalize_content_type(options)
        type = options[:content_type].value
        mime_type = MIME::Types[type].first
        return mime_type if mime_type

        raise ArgumentError, "Invalid content type: #{type.inspect}"
      end

      def normalize_query(options)
        query = Attribute.update_hash_values(options[:query], options[:variables])
        Attribute::ResolvableHash.new(query)
      end

      def normalize_body(content_type, options)
        body = options[:body]

        body =
          case content_type
          when "application/json"
            Attribute.update_hash_values(body, options[:variables])
          end

        Attribute::ResolvableHash.new(body)
      end

      def extract_authorization(options)
        SpecForge.config.authorization[:default]
      end
    end
  end
end
