# frozen_string_literal: true

module SpecForge
  class Normalizer
    class Structure < Hash
      STRUCTURE = {
        type: {
          type: [String, Array, Class],
          default: nil, # Important to default this to nil so other logic can handle it
          required: true,
          validator: :present?
        },
        default: {
          type: [String, NilClass, Numeric, Array, Hash, TrueClass, FalseClass]
        },
        required: {
          type: [TrueClass, FalseClass]
        },
        aliases: {
          type: Array,
          structure: {type: String}
        },
        structure: {
          type: Hash
        },
        validator: {
          type: String
        },
        transformer: {
          type: String
        }
      }.freeze

      attr_reader :label

      def initialize(input, label: "")
        @label = label

        # Pull in the data
        deep_merge!(input)

        # And normalize
        normalize
      end

      private

      def normalize
        # Normalize the root level keys
        transform_values!(with_key: true) do |attribute, name|
          normalize_attribute(name, attribute)
        end

        self
      end

      def normalize_attribute(attribute_name, attribute)
        case attribute
        # Shorthands for single/multiple types
        when String, Array
          hash = {type: resolve_type(attribute)}

          default = Normalizer.default(structure: STRUCTURE)
          hash.merge!(default)
        # Full syntax
        when Hash
          hash = Normalizer.raise_errors! do
            Normalizer.new(
              "#{attribute_name.in_quotes} in #{@label.in_quotes}",
              attribute,
              structure: STRUCTURE
            ).normalize
          end

          hash[:type] = resolve_type(attribute[:type])

          if hash[:structure].present?
            hash[:structure] = normalize_structure(attribute_name, hash) || {}
          end

          hash
        else
          raise ArgumentError, "Attribute #{attribute_name.in_quotes}: Expected String, Array, or Hash. Got #{attribute.inspect}"
        end
      end

      def normalize_structure(name, hash)
        if hash[:type] == Array
          normalize_attribute(name, hash[:structure])
        elsif hash[:type] == Hash
          hash[:structure].transform_values(with_key: true) { |v, k| normalize_attribute(k, v) }
        end
      end

      def resolve_type(type)
        if type == "boolean"
          [FalseClass, TrueClass]
        elsif type == "any"
          [Array, FalseClass, Hash, NilClass, Numeric, String, TrueClass]
        elsif type.instance_of?(Array)
          type.map { |t| resolve_type(t) }
        elsif type.is_a?(String)
          type.classify.constantize
        else
          type
        end
      rescue NameError => e
        raise Error, "#{e}. #{type.inspect} is not a valid type found in #{@label.in_quotes}"
      end
    end
  end
end
