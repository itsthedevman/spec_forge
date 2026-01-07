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
        value =
          @templates.each_with_object(@parsed.dup) do |(placeholder, attribute), string|
            value = attribute.value

            replacement_value =
              case value
              when Hash, Array
                value.to_json
              else
                value.to_s
              end

            string.gsub!(placeholder, replacement_value)
          end

        if @templates.size == 1
          placeholder, template_value = @templates.first
          value = cast_to_type(value, template_value.value) if @parsed == placeholder
        end

        value
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

          attribute = Attribute.from(content)

          # There is no such thing as a Literal inside a Template.
          # This makes it significantly easier to detect variables
          attribute = Attribute::Variable.new(content) if attribute.is_a?(Attribute::Literal)

          placeholder = "⬣→SF#{index}"
          templates[placeholder] = attribute
          reverse_lookup[content] = placeholder

          placeholder
        end

        [result, templates]
      end

      def cast_to_type(input, template_value)
        case template_value
        when Integer
          input.to_i
        when Float
          input.to_f
        when TrueClass, FalseClass
          input == "true"
        when Array
          input.to_a
        when Hash
          input.to_h
        when String
          input
        else
          template_value # Matchers, etc.
        end
      end
    end
  end
end
