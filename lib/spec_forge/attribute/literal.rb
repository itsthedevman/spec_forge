# frozen_string_literal: true

module SpecForge
  class Attribute
    class Literal < Attribute
      attr_reader :value

      #
      # Represents any attribute that is a literal value.
      # A literal value can be any value YAML value, except Array and Hash
      #
      def initialize(input)
        super

        @value = input
      end

      alias_method :resolve, :value
    end
  end
end
