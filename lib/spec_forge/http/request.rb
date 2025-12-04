# frozen_string_literal: true

module SpecForge
  module HTTP
    class Request < Data.define(:base_url, :url, :http_verb, :headers, :query, :body)
      #
      # Regex that attempts to match a valid header
      #
      # @return [Regexp]
      #
      HEADER = /^[A-Z][A-Za-z0-9!-]*$/

      def initialize(**options)
        base_url = options[:base_url] || ""
        url = options[:url] || ""

        http_verb = Verb.from(options[:http_verb].presence || "GET")
        query = Attribute.from(options[:query] || {})

        content = extract_content(**options.slice(:raw, :json))
        headers = transform_headers(options[:headers] || {}, content[:content_type])

        body = Attribute.from(content[:body] || {})

        super(base_url:, url:, http_verb:, headers:, query:, body:)
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

      def content_type
        headers["Content-Type"]
      end

      private

      def extract_content(raw: "", json: {})
        output = {}

        if json.present?
          output[:body] = json
          output[:content_type] = "application/json"
        else
          output[:body] = raw
          output[:content_type] = "text/plain"
        end

        output
      end

      def transform_headers(headers, detected_content_type)
        # Convert snake_case and other formats to HTTP Header-Case format
        # Examples:
        #   content_type -> Content-Type
        #   api_key -> Api-Key
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

        headers["Content-Type"] = detected_content_type if !headers.key?("Content-Type")

        Attribute.from(headers)
      end
    end
  end
end
