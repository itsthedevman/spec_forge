# frozen_string_literal: true

module SpecForge
  class Step
    class Expect < Data.define(:name, :status, :headers, :raw, :json)
      include Attribute::ToAttribute

      def initialize(name: nil, status: nil, headers: nil, raw: nil, json: nil)
        super(
          name: Attribute.from(name), # TODO: Might not be needed
          status: Attribute.from(status),
          headers: Attribute.from(headers),
          raw: Attribute.from(raw),
          json: extract_json(json)
        )
      end

      def status_matcher
        return if status.input.blank?

        status.resolve_as_matcher
      end

      def headers_matcher
        return if headers.blank?

        headers.stringify_keys.transform_values { |v| v&.resolve_as_matcher }
      end

      def json_size_matcher
        return if json[:size].blank?

        json[:size].resolve_as_matcher
      end

      def json_shape_matcher
        return if json[:shape].blank?

        json[:shape]
      end

      private

      def extract_json(json)
        return if json.blank?

        output = json.compact

        # shape and schema do not need converted to Attribute
        output[:size] = Attribute.from(output[:size]) if output[:size]
        output[:content] = Attribute.from(output[:content]) if output[:content]

        output
      end
    end
  end
end
