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
      # @param value [String, Hash] Callback name or full definition
      #
      # @return [Hash] Normalized callback hash with :name key
      #
      def normalize_callback(value)
        return value if value.is_a?(Hash)

        {name: value}
      end

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
    end
  end
end
