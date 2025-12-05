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
          string.gsub!(placeholder, attribute.value.to_s)
        end
      end

      private

      def parse_templates
        templates = {}

        result = @input.gsub(REGEX).with_index do |match, index|
          placeholder = "⬣→SF#{index}"

          content = match[2..-3].strip
          templates[placeholder] =
            if content.match?(Variable::KEYWORD_REGEX)
              Variable.new(content)
            else
              Attribute.from(content)
            end

          placeholder
        end

        [result, templates]
      end
    end
  end
end
