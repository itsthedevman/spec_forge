# frozen_string_literal: true

module SpecForge
  class Normalizer
    #
    # Manages structure definitions for the Normalizer
    #
    # Handles loading structure definitions from YAML files, processing references
    # between structures, and normalizing structure formats for consistent validation.
    #
    # @example Loading all structure definitions
    #   structures = SpecForge::Normalizer::Definition.from_files
    #
    class Definition
      #
      # Mapping of structure names to their human-readable labels
      #
      # @return [Hash<Symbol, String>]
      #
      LABELS = {
        factory_reference: "factory reference",
        global_context: "global context"
      }.freeze

      #
      # Core structure definition used to validate other structures
      #
      # Defines the valid attributes and types for structure definitions,
      # creating a meta-structure that validates other structure definitions.
      #
      # @return [Hash]
      #
      STRUCTURE = {
        type: {
          type: [String, Array, Class],
          default: nil,
          validator: :present?
        },
        default: {
          type: [String, NilClass, Numeric, Array, Hash, TrueClass, FalseClass],
          required: false
        },
        required: {
          type: [TrueClass, FalseClass],
          required: false
        },
        aliases: {
          type: Array,
          required: false,
          structure: {type: String}
        },
        structure: {
          type: Hash,
          required: false
        },
        validator: {
          type: String,
          required: false
        }
      }.freeze

      #
      # Loads normalizer definitions from YAML files
      #
      # Reads all YAML files in the normalizers directory, processes shared
      # references, and prepares them for use by the Normalizer.
      #
      # @return [Hash] A hash mapping structure names to their definitions
      #
      def self.from_files
        base_path = Pathname.new(File.expand_path("../normalizers", __dir__))
        paths = Dir[base_path.join("**/*.yml")].sort

        normalizers =
          paths.each_with_object({}) do |path, hash|
            path = Pathname.new(path)

            # Include the directory name in the path to include normalizers in directories
            name = path.relative_path_from(base_path).to_s.delete_suffix(".yml").to_sym

            input = YAML.safe_load_file(path, symbolize_names: true)
            raise Error, "Normalizer defined at #{path.to_s.in_quotes} is empty" if input.blank?

            hash[name] = new(input, label: LABELS[name] || name.to_s.humanize.downcase)
          end

        # Pull the shared structures and prepare it
        structures = normalizers.delete(:_shared).normalize

        # Merge in the normalizers to allow referencing other normalizers
        structures.merge!(normalizers.transform_values(&:input))

        # Now prepare all of the other definitions with access to references
        normalizers.transform_values!(with_key: true) do |definition, name|
          structure = definition.normalize(structures)

          {
            label: definition.label,
            structure:
          }
        end

        normalizers
      end

      ##########################################################################

      attr_reader :input, :label

      def initialize(input, label: "")
        @input = input
        @label = label
      end

      #
      # Normalizes a structure definition
      #
      # Processes references, resolves types, and ensures all attributes
      # have a consistent format for validation.
      #
      # @param shared_structures [Hash] Optional shared structures for resolving references
      #
      # @return [Hash] The normalized structure definition
      #
      def normalize(shared_structures = {})
        hash = @input.deep_dup

        # First, we'll deeply replace any references
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

      def replace_references(attributes, shared_structures)
        return if shared_structures.blank?

        # The goal is to walk down the hash and recursively replace any references
        attributes.each do |attribute_name, attribute|
          # Replace the top level reference
          replace_with_reference(attribute_name, attribute, shared_structures:)
          next unless attribute.is_a?(Hash) && attribute[:structure].present?

          # Allow structures to reference other structures
          if attribute.dig(:structure, :reference)
            replace_with_reference(
              "#{attribute_name}'s structure",
              attribute[:structure],
              shared_structures:
            )
          end

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

          raise Error, "Attribute #{attribute_name.in_quotes}: Invalid reference name. Got #{reference_name&.in_quotes}, expected one of #{structures_names} in #{@label}"
        end

        # Allows overwriting data on the reference
        attribute.reverse_merge!(reference)
      end

      def normalize_attribute(attribute_name, attribute)
        case attribute
        when String, Array # Array is multiple types
          hash = {type: resolve_type(attribute)}

          default = Normalizer.default(structure: STRUCTURE)
          hash.merge!(default)
        when Hash
          hash = Normalizer.raise_errors! do
            Normalizer.new(
              "#{attribute_name.in_quotes} in #{@label}",
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
        raise Error, "#{e}. #{type.inspect} is not a valid type found in #{@label}"
      end
    end
  end
end
