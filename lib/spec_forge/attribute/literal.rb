# frozen_string_literal: true

module SpecForge
  class Attribute
    class Literal < Attribute
      REGEX_REGEX = /^\/.+\/[mnix\s]*$/i

      attr_reader :value

      #
      # Represents any attribute that is a literal value.
      # A literal value can be any value YAML value, except Array and Hash
      #
      def initialize(input)
        super

        @value =
          case input
          when REGEX_REGEX
            Regexp.new(input)
          else
            input
          end
      end
    end
  end
end
