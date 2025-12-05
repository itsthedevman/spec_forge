# frozen_string_literal: true

module SpecForge
  class Step
    class Expect < Data.define(:name, :status, :headers, :raw, :json)
      def initialize(name: nil, status: nil, headers: nil, raw: nil, json: nil)
        super(
          name: Attribute.from(name),
          status: Attribute.from(status),
          headers: Attribute.from(headers),
          raw: Attribute.from(raw),
          json: Attribute.from(json)
        )
      end

      # def as_matchers
      #   {
      #     status: status.resolve_as_matcher,
      #     json: resolve_json_matcher,
      #     headers: resolve_hash_matcher(headers)
      #   }
      # end

      def description
        description = "is expected to respond with"

        description += if status.is_a?(Attribute::Literal)
          " #{HTTP.status_code_to_description(status.input).in_quotes}"
        else
          " the expected status code"
        end

        size = json.size

        if Type.array?(json)
          description +=
            " and a JSON array that contains #{size} #{"item".pluralize(size)}"
        elsif Type.hash?(json) && size > 0
          keys = json.keys.join_map(", ", &:in_quotes)

          description +=
            " and a JSON object that contains #{"key".pluralize(size)}: #{keys}"
        end

        description
      end

      private

      def resolve_json_matcher
        case json
        when HashLike
          resolve_hash_matcher(json)
        else
          json.resolve_as_matcher
        end
      end

      def resolve_hash_matcher(hash)
        hash.transform_values(&:resolve_as_matcher).stringify_keys
      end
    end
  end
end
