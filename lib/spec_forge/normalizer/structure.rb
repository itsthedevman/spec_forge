# frozen_string_literal: true

module SpecForge
  class Normalizer
    class Structure < Hash
      STRUCTURE = {
        type: {
          type: [String, Array, Class],
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
        }
      }.freeze

      MAX_DEPTH = 3

      attr_reader :label

      def initialize(input, label: "", references: {})
        @label = label

        # Pull in the data
        deep_merge!(input)

        # And normalize
        normalize(references)
      end

      private

      def normalize(references)
        # Replace any references
        replace_references(self, references)

        # Normalize the root level keys
        transform_values!(with_key: true) do |attribute, name|
          next if STRUCTURE.key?(name)

          normalize_attribute(name, attribute)
        end

        # Normalize the underlying structures
        each do |name, attribute|
          next unless attribute.is_a?(Hash)

          structure = attribute[:structure]
          next if structure.blank?

          attribute[:structure] = normalize_structure(name, attribute)
        end

        self
      end

      def replace_references(attributes, references, level:)
        return if references.blank?

        # The goal is to walk down the hash and recursively replace any references
        attributes.each do |attribute_name, attribute|
          # Replace the top level reference
          replace_with_reference(attribute_name, attribute, references:)
          next unless attribute.is_a?(Hash) && attribute[:structure].present?

          # Allow structures to reference other structures
          if attribute.dig(:structure, :reference)
            replace_with_reference(
              "#{attribute_name}'s structure",
              attribute[:structure],
              references:
            )
          end

          # Recursively replace any structures that have references
          if [Array, "array"].include?(attribute[:type])
            result = replace_references(attribute.slice(:structure), references, level:)
            attribute.merge!(result) if result
          elsif [Hash, "hash"].include?(attribute[:type])
            replace_references(attribute[:structure], references, level:)
          end
        end
      end

      def replace_with_reference(attribute_name, attribute, references: {})
        return unless attribute.is_a?(Hash) && attribute.key?(:reference)

        reference_name = attribute.delete(:reference)
        reference = references[reference_name.to_sym]

        if reference.nil?
          structures_names = references.keys.map(&:in_quotes).to_or_sentence

          raise Error, "Attribute #{attribute_name.in_quotes}: Invalid reference name. Got #{reference_name&.in_quotes}, expected one of #{structures_names} in #{@label}"
        end

        # Allows overwriting data on the reference
        attribute.reverse_merge!(reference)
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
          [TrueClass, FalseClass]
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
