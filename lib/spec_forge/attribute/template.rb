# frozen_string_literal: true

module SpecForge
  class Attribute
    class Template < Attribute
      REGEX = /\{\{\s*[\w.]+\s*\}\}/

      def initialize(...)
        super

        @parsed, @templates = parse_templates
      end

      def value
        @templates.each_with_object(@parsed.dup) do |(placeholder, attribute), string|
          value = attribute.value

          replacement_value =
            case value
            when HashLike, ArrayLike
              value.to_json
            else
              value.to_s
            end

          string.gsub!(placeholder, replacement_value)
        end
      end

      private

      def parse_templates
        templates = {}
        reverse_lookup = {}

        result = @input.gsub(REGEX).with_index do |match, index|
          content = match[2..-3].strip

          # We've already processed this content, use the same placeholder
          if (placeholder = reverse_lookup[content])
            next placeholder
          end

          placeholder = "⬣→SF#{index}"

          templates[placeholder] = Attribute.from(content)
          reverse_lookup[content] = placeholder

          placeholder
        end

        [result, templates]
      end
    end
  end
end
