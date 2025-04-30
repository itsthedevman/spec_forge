# frozen_string_literal: true

module SpecForge
  class Normalizer
    class Definition
      LABELS = {
        constraint: "expect",
        factory_reference: "factory reference",
        global_context: "global context"
      }.freeze

      STRUCTURE = {
        type: {
          type: [String, Array, Class],
          default: nil,
          validator: :present?
        },
        default: {
          type: [String, NilClass, Numeric, Array, Hash, TrueClass, FalseClass],
          default: nil
        },
        aliases: {
          type: Array,
          default: [],
          structure: {type: String}
        },
        structure: {
          type: Hash,
          default: {}
        },
        validator: {
          type: String,
          default: nil
        }
      }.freeze

      def self.from_files
        base_path = Pathname.new(File.expand_path("../normalizers", __dir__))
        paths = Dir[base_path.join("**/*.yml")].sort

        normalizers =
          paths.each_with_object({}) do |path, hash|
            path = Pathname.new(path)

            definition = new(path)
            hash[definition.normalizer_name] = definition
          end

        # Pull the shared structures and prepare it
        structures = normalizers.delete("_shared").to_h

        # Now prepare all of the other definitions with access to references
        normalizers.transform_values!(with_key: true) do |definition, name|
          structure = definition.to_h(structures)

          {
            label: LABELS[name.to_sym] || name.humanize.downcase,
            structure:
          }
        end

        normalizers
      end

      attr_reader :normalizer_name

      def initialize(path)
        @path = path
        @normalizer_name = path.basename(".yml").to_s
      end

      def to_h(structures = {})
        hash = load_from_file

        # Allow referencing other normalizers
        shared_structures = hash.merge(structures)

        # First, we'll deeply replace any references - _shared basically skips this
        replace_references(hash, shared_structures)

        # Second, normalize the root level keys
        hash.transform_values!(with_key: true) do |attribute, name|
          next if STRUCTURE.key?(name)

          normalize_attribute(name, attribute)
        end

        # Third, normalize the underlying structures
        hash.each do |name, attribute|
          next unless attribute.is_a?(Hash)

          structure = attribute[:structure]
          next if structure.blank?

          attribute[:structure] = normalize_structure(name, attribute)
        end

        hash
      end

      private

      def load_from_file
        hash = YAML.safe_load_file(@path, symbolize_names: true)
        raise Error, "Normalizer defined at #{@path.to_s.in_quotes} is empty" if hash.blank?

        hash
      end

      def replace_references(attributes, shared_structures)
        return if shared_structures.blank?

        attributes.each do |attribute_name, attribute|
          # Replace the top level reference
          replace_with_reference(attribute_name, attribute, shared_structures:)
          next unless attribute.is_a?(Hash) && attribute[:structure].present?

          # Recursively replace any structures that have references
          if [Array, "array"].include?(attribute[:type])
            result = replace_references(attribute.slice(:structure), shared_structures)
            attribute.merge!(result)
          elsif [Hash, "hash"].include?(attribute[:type])
            replace_references(attribute[:structure], shared_structures)
          end
        end
      end

      def replace_with_reference(attribute_name, attribute, shared_structures: {})
        return unless attribute.is_a?(Hash) && attribute.key?(:reference)

        reference_name = attribute.delete(:reference)
        reference = shared_structures[reference_name.to_sym]

        if reference.nil?
          structures_names = shared_structures.keys.map(&:in_quotes).to_or_sentence

          raise Error, "Attribute #{attribute_name.in_quotes}: Invalid reference name. Got #{ref_name&.in_quotes}, expected one of #{structures_names} in #{@path}"
        end

        # Allows overwriting data on the reference
        attribute.reverse_merge!(reference)
      end

      def normalize_attribute(attribute_name, attribute)
        case attribute
        when String, Array # Array is multiple types
          hash = {type: resolve_type(attribute)}
          hash.merge!(Normalizer.default(structure: STRUCTURE))
          hash
        when Hash
          hash = Normalizer.raise_errors! do
            Normalizer.new(
              "#{attribute_name.in_quotes} in #{@path}",
              attribute,
              structure: STRUCTURE
            ).normalize
          end

          hash[:type] = resolve_type(attribute[:type])

          hash[:structure] =
            if hash[:structure].present?
              normalize_structure(attribute_name, hash) || {}
            else
              {}
            end

          hash
        else
          raise ArgumentError, "Attribute #{attribute_name.in_quotes}: Expected String or Hash, got #{attribute.inspect}"
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
        raise Error, "#{e}. #{type.inspect.in_quotes} is not a valid type found in #{@path}"
      end
    end
  end
end
