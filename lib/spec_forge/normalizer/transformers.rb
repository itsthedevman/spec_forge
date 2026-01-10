# frozen_string_literal: true

module SpecForge
  class Normalizer
    #
    # Provides transformation functions for normalizer structure definitions
    #
    # Transformers modify values during normalization, such as converting
    # shorthand syntax into full structures or normalizing type definitions.
    #
    class Transformers
      include Singleton

      #
      # Calls a transformer method with the given value
      #
      # @param method_name [Symbol, String] The transformer method to call
      # @param value [Object] The value to transform
      #
      # @return [Object] The transformed value
      #
      def self.call(method_name, value)
        instance.public_send(method_name, value)
      end

      #
      # Normalizes include values to an array of blueprint names
      #
      # @param value [String, Array<String>] Include value(s)
      #
      # @return [Array<String>] Normalized blueprint names without extensions
      #
      def normalize_includes(value)
        Array(value).map! { |name| name.delete_suffix(".yml").delete_suffix(".yaml") }
      end

      #
      # Normalizes callback shorthand into full hash format
      #
      # Converts string callback names into the full hash structure with
      # a :name key. Hashes pass through unchanged. Arrays are processed
      # recursively to normalize each element.
      #
      # @param value [String, Hash, Array] Callback name, full definition, or array of callbacks
      #
      # @return [Hash, Array<Hash>] Normalized callback hash(es) with :name key
      #
      def normalize_callback(value)
        case value
        when Hash
          value
        when Array
          value.map { |v| normalize_callback(v) }
        else
          {name: value}
        end
      end

      #
      # Normalizes a shape definition into a structured schema format
      #
      # Converts shorthand shape syntax (arrays, hashes, type strings) into
      # the full schema structure with :type, :pattern, and :structure keys.
      #
      # @param value [Array, Hash, String] The shape definition to normalize
      #
      # @return [Hash] Normalized schema structure
      #
      # @raise [ArgumentError] If value is nil
      #
      def normalize_shape(value)
        raise ArgumentError, "Shape cannot be nil" if value.nil?

        case value
        when Array
          shape = {type: [Array]}

          if value.size == 1
            shape[:pattern] = normalize_shape(value.first)
          elsif value.size > 1
            shape[:structure] = value.map { |i| normalize_shape(i) }
          else
            []
          end

          shape
        when Hash
          {
            type: [Hash],
            structure: value.transform_values { |v| normalize_shape(v) }
          }
        when String
          {type: Type.from_string(value)}
        end
      end

      #
      # Normalizes a schema definition by converting type strings to classes
      #
      # Recursively processes schema definitions, converting string type
      # specifications into their Ruby class equivalents.
      #
      # @param value [Array, Hash, String] The schema definition to normalize
      #
      # @return [Hash, Array] Normalized schema with type classes
      #
      # @raise [ArgumentError] If value is nil
      #
      def normalize_schema(value)
        raise ArgumentError, "Schema cannot be nil" if value.nil?

        case value
        when Array
          value.each { |v| normalize_schema(v) }
        when Hash
          if (type = value[:type]) && type.is_a?(String)
            value[:type] = Type.from_string(type)
          end

          if (structure = value[:structure])
            value[:structure] =
              case structure
              when Array
                structure.map { |v| normalize_schema(v) }
              when Hash
                structure.transform_values { |v| normalize_schema(v) }
              end
          end

          if (pattern = value[:pattern])
            value[:pattern] = normalize_schema(pattern)
          end

          value
        when String
          {type: Type.from_string(value)}
        end
      end

      #
      # Returns the absolute value of a number
      #
      # @param value [Numeric, nil] The value to convert
      #
      # @return [Numeric, nil] The absolute value, or nil if input is nil
      #
      def abs(value)
        value&.abs
      end
    end
  end
end
