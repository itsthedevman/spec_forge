# frozen_string_literal: true

module SpecForge
  module HTTP
    class Request < Data.define(:base_url, :url, :http_method, :headers, :query, :body)
      HEADER = /^[A-Z][A-Za-z0-9!-]*$/

      def initialize(**input)
        url = extract_url(input)
        base_url = extract_base_url(input)
        http_method = normalize_http_method(input)
        headers = normalize_headers(input)
        query = normalize_query(input)
        body = normalize_body(input)

        super(base_url:, url:, http_method:, headers:, query:, body:)
      end

      def http_verb
        http_method.name.downcase
      end

      def to_h
        super.transform_values { |v| v.respond_to?(:resolve) ? v.resolve : v }
      end

      private

      def extract_base_url(input)
        input[:base_url]
      end

      def extract_url(input)
        input[:url]
      end

      def normalize_http_method(input)
        method = input[:http_method].presence || "GET"

        if method.is_a?(String)
          Verb.from(method)
        else
          method
        end
      end

      def normalize_headers(input)
        headers = input[:headers].transform_keys do |key|
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

      def normalize_query(input)
        Attribute.from(input[:query])
      end

      def normalize_body(input)
        Attribute.from(input[:body])
      end
    end
  end
end
