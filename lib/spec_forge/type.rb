# frozen_string_literal: true

module SpecForge
  #
  # Provides helper methods for type conversion
  #
  module Type
    def self.from_string(input)
      raise ArgumentError, "Input is nil" if input.nil?

      # Handle nullable prefix
      nullable = input.start_with?("?")
      base_type = nullable ? input[1..] : input

      types =
        case base_type
        when "string"
          [String]
        when "number", "numeric"
          [Integer, Float]
        when "integer"
          [Integer]
        when "float"
          [Float]
        when "bool", "boolean"
          [TrueClass, FalseClass]
        when "array"
          [Array]
        when "hash", "object"
          [Hash]
        when "null", "nil"
          [NilClass]
        else
          raise ArgumentError,
            "Unknown type: #{base_type.in_quotes}. Valid types: string, number/numeric, integer, float, boolean/bool, array, hash/object, null/nil"
        end

      # Don't forget if it is nullable!
      types << NilClass if nullable

      types.uniq
    end
  end
end
