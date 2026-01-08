# frozen_string_literal: true

module SpecForge
  #
  # Utilities for converting between Ruby classes and type strings
  #
  # Type provides bidirectional conversion between Ruby types (Integer, String, etc.)
  # and their string representations ("integer", "string", etc.) used in YAML
  # schema definitions. Supports nullable types with the "?" prefix.
  #
  module Type
    class << self
      # Mapping from Ruby classes to type string names
      #
      # @return [Hash{Class => String}]
      CLASS_TO_STRING = {
        Integer => "integer",
        Float => "float",
        String => "string",
        Hash => "hash",
        Array => "array",
        TrueClass => "boolean",
        FalseClass => "boolean",
        NilClass => "null"
      }.freeze

      # Mapping from type string names to Ruby classes
      #
      # @return [Hash{String => Array<Class>}]
      STRING_TO_CLASS = {
        "string" => [String],
        "number" => [Integer, Float],
        "numeric" => [Integer, Float],
        "integer" => [Integer],
        "float" => [Float],
        "bool" => [TrueClass, FalseClass],
        "boolean" => [TrueClass, FalseClass],
        "array" => [Array],
        "hash" => [Hash],
        "object" => [Hash],
        "null" => [NilClass],
        "nil" => [NilClass]
      }.freeze

      #
      # Converts a type string to an array of Ruby classes
      #
      # Supports nullable types with the "?" prefix (e.g., "?string" returns [String, NilClass]).
      #
      # @param input [String] The type string (e.g., "integer", "?string", "boolean")
      #
      # @return [Array<Class>] Array of Ruby classes matching the type
      #
      # @raise [ArgumentError] If input is nil or unknown type
      #
      # @example
      #   Type.from_string("integer")   # => [Integer]
      #   Type.from_string("?string")   # => [String, NilClass]
      #   Type.from_string("boolean")   # => [TrueClass, FalseClass]
      #
      def from_string(input)
        raise ArgumentError, "Input is nil" if input.nil?

        # Handle nullable prefix
        nullable = input.start_with?("?")
        base_type = nullable ? input[1..] : input

        types = STRING_TO_CLASS[base_type.downcase].dup

        if types.nil?
          raise ArgumentError,
            "Unknown type: #{base_type.in_quotes}. Valid types: string, number/numeric, integer, float, boolean/bool, array, hash/object, null/nil"
        end

        # Don't forget if it is nullable!
        types << NilClass if nullable

        types.uniq
      end

      #
      # Converts Ruby classes to their type string representation
      #
      # Handles nullable types (includes NilClass) by adding "?" prefix.
      # Normalizes boolean types (TrueClass/FalseClass) to single "boolean".
      #
      # @param types [Array<Class>] One or more Ruby classes
      #
      # @return [String, Array<String>] Type string or array if multiple distinct types
      #
      # @example
      #   Type.to_string(Integer)                    # => "integer"
      #   Type.to_string(String, NilClass)           # => "?string"
      #   Type.to_string(TrueClass, FalseClass)      # => "boolean"
      #   Type.to_string(Integer, String)            # => ["integer", "string"]
      #
      def to_string(*types)
        types = types.map { |k| CLASS_TO_STRING[k] }

        null = CLASS_TO_STRING[NilClass] # Just in case the name changes
        if types.delete(null)
          # We removed the nil above, no other types means this is just nil. No need to continue processing
          return null if types.empty?

          types.map! { |t| "?#{t}" }
        end

        # Remove "boolean", "boolean" that happens with TrueClass/FalseClass
        types.uniq!

        (types.size == 1) ? types.first : types
      end
    end
  end
end
