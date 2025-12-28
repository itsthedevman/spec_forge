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
          json: extract_json_expectations(json)
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

        headers.stringify_keys.transform_values { |v| v&.resolve_as_matcher }
      end

      def json_size_matcher
        return if json[:size].blank?

        json[:size].resolve_as_matcher
      end

      def json_structure_matcher
        return if json[:structure].blank?

        json[:structure].resolve_as_matcher
      end

      private

      def extract_json_expectations(json)
        size = json[:size] ? Attribute.from(json[:size]) : nil
        content = json[:content] ? Attribute.from(json[:content]) : nil

        structure = if (structure = json[:structure])
          Attribute.from(convert_type_structure(structure))
        end

        pattern = if (pattern = json[:pattern])
          Attribute.from(convert_type_structure(pattern))
        end

        {
          size:,
          structure:,
          pattern:,
          content:
        }
      end

      def convert_type_structure(data)
        case data
        when Array
          data.map { |item| convert_type_structure(item) }
        when Hash
          data.transform_values { |value| convert_type_structure(value) }
        else
          Type.from_string(data)
        end
      end
    end
  end
end
