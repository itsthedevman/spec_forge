# frozen_string_literal: true

module SpecForge
  class Step
    class Expect < Data.define(:name, :status, :headers, :raw, :json)
      include Attribute::ToAttribute

      def initialize(name: nil, status: nil, headers: nil, raw: nil, json: nil)
        super(
          name: Attribute.from(name),
          status: Attribute.from(status),
          headers: Attribute.from(headers),
          raw: Attribute.from(raw),
          json: Attribute.from(json)
        )
      end

      def description
        # Use custom name if provided
        return name.resolved if name.resolved.present?

        parts = []

        # Status with HTTP description
        if status.input.present?
          resolved_status = status.resolved

          parts << if resolved_status.is_a?(Integer)
            HTTP.status_code_to_description(resolved_status)
          else
            "expected status"
          end
        end

        # Headers count
        if Type.hash?(headers) && headers.size > 0
          parts << "headers (#{headers.size})"
        end

        # Raw body
        parts << "raw" if raw.input.present?

        # JSON checks
        if Type.hash?(json)
          parts << "size" if json[:size].present?

          if (structure = json[:structure]) && structure.present?
            structure_type = Type.array?(structure) ? "array" : "hash"
            parts << "structure (#{structure_type})"
          end

          parts << "content" if json[:content].present?
        end

        parts.join(", ")
      end

      def status_matcher
        return if status.input.blank?

        status.resolve_as_matcher
      end

      def headers_matcher
        return if headers.blank?

        headers.transform_values(&:resolve_as_matcher)
      end

      private

      def resolve_json_matcher
        case json
        when HashLike
          json.transform_values(&:resolve_as_matcher)
        else
          json.resolve_as_matcher
        end
      end
    end
  end
end
