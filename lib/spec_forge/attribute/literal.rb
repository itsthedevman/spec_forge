# frozen_string_literal: true

module SpecForge
  class Attribute
    #
    # Represents an attribute that is a literal value
    #
    # This is the simplest form of attribute, storing values like strings, numbers,
    # and booleans without any processing.
    #
    # @example Basic usage in YAML
    #   name: "John Doe"
    #   age: 42
    #   active: true
    #
    class Literal < Attribute
      # @return [Object] The literal value
      attr_reader :value

      #
      # Creates a new literal attribute with the specified value
      #
      # @param input [Object] The value to store
      #
      def initialize(input)
        super

        @value = input
      end

      alias_method :resolve, :value
    end
  end
end
