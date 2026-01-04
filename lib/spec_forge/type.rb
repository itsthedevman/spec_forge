# frozen_string_literal: true

module SpecForge
  module Type
    class << self
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
