# frozen_string_literal: true

module SpecForge
  module HTTP
    class Request < Data.define(:base_url, :url, :http_method, :headers, :query, :body)
      HEADER = /^[A-Z][A-Za-z0-9!-]*$/

      def initialize(base_url:, url:, http_method:, headers:, query:, body:)
        http_method = normalize_http_method(http_method)
        headers = normalize_headers(headers)
        query = normalize_query(query)
        body = normalize_body(body)

        super
      end

      def http_verb
        http_method.name.downcase
      end

      def to_h
        super.transform_values { |v| v.respond_to?(:resolve) ? v.resolve : v }
      end

      private

      def normalize_http_method(http_method)
        method = http_method.presence || "GET"

        if method.is_a?(String)
          Verb.from(method)
        else
          method
        end
      end

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

      def normalize_query(query)
        Attribute.from(query)
      end

      def normalize_body(body)
        Attribute.from(body)
      end
    end
  end
end
