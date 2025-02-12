# frozen_string_literal: true

module SpecForge
  module HTTP
    class Request < Data.define(:base_url, :url, :http_method, :headers, :query, :body)
      HEADER = /^[A-Z][A-Za-z0-9!-]*$/

      #
      # Initializes a new Request instance with the given options
      #
      # @param [Hash] options The options to create the Request with
      #
      # @option options [String] :url The request URL
      #
      # @option options [String, Verb] :http_method The HTTP method to use
      #
      # @option options [Hash] :headers Any headers
      #
      # @option options [Hash] :query The query parameters for the request (defaults to {})
      #
      # @option options [Hash] :body The request body (defaults to {})
      #
      def initialize(**options)
        base_url = extract_base_url(options)
        url = extract_url(options)
        headers = normalize_headers(options)
        http_method = normalize_http_method(options)
        query = normalize_query(options)
        body = normalize_body(options)

        super(base_url:, url:, http_method:, headers:, query:, body:)
      end

      def http_verb
        http_method.name.downcase
      end

      private

      def extract_base_url(options)
        options[:base_url].value
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

      def normalize_headers(options)
        headers = options[:headers].transform_keys do |key|
          key = key.to_s

          # If the key is already like a header, don't change it
          if key.match?(HEADER)
            key
          else
            # content_type => Content-Type
            key.downcase.titleize.gsub(/\s+/, "-")
          end
        end

        headers = Attribute.bind_variables(headers, options[:variables])
        Attribute::ResolvableHash.new(headers)
      end

      def normalize_query(options)
        query = Attribute.bind_variables(options[:query], options[:variables])
        Attribute::ResolvableHash.new(query)
      end

      def normalize_body(options)
        body = Attribute.bind_variables(options[:body], options[:variables])
        Attribute::ResolvableHash.new(body)
      end
    end
  end
end
