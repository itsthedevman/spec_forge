# frozen_string_literal: true

module SpecForge
  module HTTP
    REQUEST_ATTRIBUTES = [:base_url, :url, :http_verb, :headers, :query, :body].freeze

    class Request < Data.define(*REQUEST_ATTRIBUTES)
      HEADER = /^[A-Z][A-Za-z0-9!-]*$/

      def initialize(base_url:, url:, http_verb:, headers:, query:, body:)
        http_verb = Verb.from(http_verb.presence || "GET")
        query = Attribute.from(query)
        body = Attribute.from(body)
        headers = normalize_headers(headers)

        super
      end

      def to_h
        super.transform_values { |v| v.respond_to?(:resolve) ? v.resolve : v }
      end

      private

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
