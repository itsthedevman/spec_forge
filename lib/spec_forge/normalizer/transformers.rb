# frozen_string_literal: true

module SpecForge
  class Normalizer
    class Transformers
      include Singleton

      def self.call(method_name, value)
        instance.public_send(method_name, value)
      end

      def normalize_includes(value)
        Array(value).map! { |name| name.delete_suffix(".yml").delete_suffix(".yaml") }
      end

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
