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
        @templates.each_with_object(@parsed) do |(placeholder, attribute), string|
          string.gsub!(placeholder, attribute.value)
        end
      end

      private

      def parse_templates
        templates = {}

        result = @input.gsub(REGEX).with_index do |match, index|
          placeholder = "⬣→SF#{index}"
          templates[placeholder] = Attribute.from(match[2..-3].strip)

          placeholder
        end

        [result, templates]
      end
    end
  end
end
