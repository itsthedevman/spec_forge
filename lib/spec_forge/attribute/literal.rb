# frozen_string_literal: true

module SpecForge
  class Attribute
    class Literal < Attribute
      REGEX_REGEX = /^\/.+\/[mnix\s]*$/i

      attr_reader :value

      def initialize(input)
        super

        @value =
          case input
          when Array
            input.map { |v| Attribute.from(v) }
          when Hash
            input.transform_values { |v| Attribute.from(v) }
          when REGEX_REGEX
            Regexp.new(input)
          else
            input
          end
      end
    end
  end
end
