# frozen_string_literal: true

module SpecForge
  class Step
    class Expect < Data.define(:name, :status, :headers, :raw, :json)
      include Attribute::ToAttribute

      def initialize(name: nil, status: nil, headers: nil, raw: nil, json: nil)
        super(
          name:,
          status: status ? Attribute.from(status) : nil,
          headers: headers ? Attribute.from(headers) : nil,
          raw: raw ? Attribute.from(raw) : nil,
          json: extract_json(json)
        )
      end

      def size
        [
          status,
          headers,
          raw,
          json[:size],
          json[:schema],
          json[:content]
        ].compact_blank.size
      end

      def status_matcher
        return if status.blank?

        status.resolve_as_matcher
      end

      def headers_matcher
        return if headers.blank?

        headers.stringify_keys.transform_values { |v| v&.resolve_as_matcher }
      end

      def json_size_matcher
        json[:size]&.resolve_as_matcher
      end

      def json_schema
        json[:schema]
      end

      def json_content_matcher
        json[:content]&.resolve_as_matcher
      end

      private

      def extract_json(json)
        return {} if json.blank?

        output = {}

        output[:content] = Attribute.from(json[:content]) if json[:content]
        output[:size] = Attribute.from(json[:size]) if json[:size]
        output[:schema] = json[:schema] || json[:shape]

        output
      end
    end
  end
end
