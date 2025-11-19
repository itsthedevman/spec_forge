# frozen_string_literal: true

module SpecForge
  #
  # This class provides a powerful system for validating and normalizing input data
  # according to defined structures. It handles type checking, default values,
  # references between structures, and custom validation logic.
  #
  # == Structure Definitions
  #
  # Structures define validation rules as YAML files in the lib/spec_forge/normalizers directory:
  #
  #   # Example structure (users.yml)
  #   name:
  #     type: String
  #     required: true
  #
  #   age:
  #     type: Integer
  #     default: 0
  #
  #   settings:
  #     type: Hash
  #     structure:
  #       notifications:
  #         type: Boolean
  #         default: true
  #
  # == Core Attribute Behaviors
  #
  # 1. With 'default:' - Always included in output, using default if nil
  # 2. With 'required: false' - Omitted from output if nil
  # 3. Default behavior - Required, errors if missing/nil
  #
  # == Available Options
  #
  # * type: - Required. Class name or array of class names (string, integer, hash, etc.)
  # * default: - Optional. Default value if attribute is nil
  # * required: - Optional. Set to false to make attribute optional
  # * aliases: - Optional. Alternative keys to check for value
  # * structure: - Optional. Sub-structure for nested objects
  # * validator: - Optional. Custom validation method (see Validators)
  # * reference: - Optional. Reference another structure definition (e.g., reference: headers)
  # * description: - Optional. TODO
  # * examples: - Optional. TODO
  #
  # == Structure References
  #
  # References allow reusing common structures:
  #
  #   # In your YAML definition:
  #   user_id:
  #     reference: id    # Will inherit all properties from the 'id' structure
  #     required: false  # Can override specific properties
  #
  #   # Nested structure references:
  #   settings:
  #     type: Hash
  #     structure:
  #       email_prefs:
  #         reference: email_preferences  # References another complete structure
  #
  # == Common Usage Patterns
  #
  # Basic Normalization:
  #   result = SpecForge::Normalizer.normalize!({name: "Test"}, using: :user)
  #
  # Using Custom Structure:
  #   structure = {count: {type: Integer, default: 0}}
  #   result = SpecForge::Normalizer.normalize!({}, using: structure, label: "counter")
  #
  # Getting Default Values:
  #   defaults = SpecForge::Normalizer.default(:user)
  #
  # == Error Handling
  #
  # Validation errors are collected during normalization and can be:
  # - Raised via normalize! method
  # - Returned as a set via normalize method
  #
  # == Creating Custom Structures
  #
  # Add YAML files to lib/spec_forge/normalizers/ directory:
  # - Use '_shared.yml' for common structures that can be referenced
  # - Create custom validators in Normalizer::Validators class
  # - Specify labels for error messages with default_label method
  #
  class Normalizer
    class << self
      #
      # Collection of structure definitions used for validation
      #
      # Contains all the structure definitions loaded from YAML files,
      # indexed by their name. Each structure defines the expected format,
      # types, and validation rules for a specific data structure.
      #
      # @return [Hash<Symbol, Hash>] Hash mapping structure names to their definitions
      #
      # @example Accessing a structure definition
      #   spec_structure = SpecForge::Normalizer.structures[:spec]
      #   url_definition = spec_structure[:structure][:url]
      #
      attr_reader :structures

      #
      # Normalizes input data against a structure with error raising
      #
      # Same as #normalize but raises an error if validation fails.
      #
      # @param input [Hash] The data to normalize
      # @param using [Symbol, Hash] Either a predefined structure name or a custom structure
      # @param label [String, nil] A descriptive label for error messages
      #
      # @return [Hash] The normalized data
      #
      # @raise [Error::InvalidStructureError] If validation fails
      #
      # @example Using a predefined structure
      #   SpecForge::Normalizer.normalize!({url: "/users"}, using: :spec)
      #
      # @example Using a custom structure
      #   structure = {name: {type: String}}
      #   SpecForge::Normalizer.normalize!({name: "Test"}, using: structure, label: "custom")
      #
      def normalize!(input, using:, label: nil)
        raise_errors! { normalize(input, using:, label:) }
      end

      #
      # Normalizes input data against a structure without raising errors
      #
      # Validates and transforms input data according to a structure definition,
      # collecting any validation errors rather than raising them. This method
      # is the underlying implementation used by normalize! but returns errors
      # instead of raising them.
      #
      # @param input [Hash] The data to normalize
      # @param using [Symbol, Hash] Either a predefined structure name or a custom structure
      # @param label [String, nil] A descriptive label for error messages
      #
      # @return [Array<Hash, Set>] A two-element array containing:
      #   1. The normalized data
      #   2. A set of any validation errors encountered
      #
      def normalize(input, using:, label: nil)
        # Since normalization is based on a structured hash, :using can be passed a Hash
        # to skip using a predefined normalizer.
        if using.is_a?(Hash)
          structure = using

          if label.blank?
            raise ArgumentError, "A label must be provided when using a custom structure"
          end
        else
          data = @structures[using.to_sym]

          # We have a predefined structure and structures all have labels
          label ||= data[:label]
          structure = data[:structure]
        end

        # Ensure we have a structure
        if !structure.is_a?(Hash)
          structures = @structures.keys.map(&:in_quotes).to_or_sentence

          raise ArgumentError,
            "Invalid structure or name. Got #{using}, expected one of #{structures}"
        end

        # This is checked down here because it felt like it belonged...
        # and because of that pesky label
        raise Error::InvalidTypeError.new(input, Hash, for: label) if !Type.hash?(input)

        new(label, input, structure:).normalize
      end

      #
      # Returns the default values for a structure
      #
      # Creates a hash of defaults based on a structure definition. Handles optional
      # values, nested structures, and type-specific default generation.
      #
      # @param name [Symbol, nil] Name of a predefined structure to use
      # @param structure [Hash, nil] Custom structure definition (used if name not provided)
      # @param include_optional [Boolean] Whether to include non-required fields with no default
      #
      # @return [Hash] A hash of default values based on the structure
      #
      # @example Getting defaults for a predefined structure
      #   SpecForge::Normalizer.default(:spec)
      #   # => {debug: false, variables: {}, headers: {}, ...}
      #
      # @example Getting defaults for a custom structure
      #   structure = {name: {type: String, default: "Unnamed"}}
      #   SpecForge::Normalizer.default(structure: structure)
      #   # => {name: "Unnamed"}
      #
      def default(name = nil, structure: nil, include_optional: false)
        structure ||= @structures.dig(name.to_sym, :structure)

        if !structure.is_a?(Hash)
          raise ArgumentError, "Invalid structure. Provide either the name of the structure ('name') or a hash ('structure')"
        end

        default_from_structure(structure, include_optional:)
      end

      #
      # Loads normalizer structure definitions from YAML files
      #
      # Reads YAML files in the normalizers directory and creates structure
      # definitions for use in validation and normalization.
      #
      # @return [Hash] A hash of loaded structure definitions
      #
      # @api private
      #
      def load_from_files
        base_path = Pathname.new(File.expand_path("../normalizers", __dir__))
        paths = Dir[base_path.join("**/*.yml")].sort

        structures =
          paths.each_with_object({}) do |path, hash|
            path = Pathname.new(path)

            # Include the directory name in the path to include normalizers in directories
            name = path.relative_path_from(base_path).to_s.delete_suffix(".yml").to_sym

            input = YAML.safe_load_file(path, symbolize_names: true)
            raise Error, "Normalizer defined at #{path.to_s.in_quotes} is empty" if input.blank?

            hash[name] = Structure.new(input, label: LABELS[name] || name.to_s.humanize.downcase)
          end

        # # Pull the shared structures and prepare it
        # references = structures.delete(:_shared).normalize

        # # Merge in the normalizers to allow referencing other normalizers
        # references.merge!(structures.transform_values(&:input))

        # # Now prepare all of the other definitions with access to references
        # normalizers.transform_values!(with_key: true) do |definition, name|
        #   structure = definition.normalize(references)

        #   {
        #     label: definition.label,
        #     structure:
        #   }
        # end

        # normalizers

        @structures = structures
      end

      #
      # Raises any errors collected by the block
      #
      # @yield Block that returns [output, errors]
      # @yieldreturn [Array<Object, Set>] The result and any errors
      #
      # @return [Object] The normalized output if successful
      #
      # @raise [Error::InvalidStructureError] If any errors were encountered
      #
      # @api private
      #
      def raise_errors!(&block)
        errors = Set.new

        begin
          output, new_errors = yield
          errors.merge(new_errors) if new_errors.size > 0
        rescue => e
          errors << e
        end

        raise Error::InvalidStructureError.new(errors) if errors.size > 0

        output
      end

      # Private methods
      include Default
    end

    #
    # Creates a normalizer for normalizing Hash data based on a structure
    #
    # @param label [String] A label that describes the data itself
    # @param input [Hash] The data to normalize
    # @param structure [Hash] The structure to normalize the data to
    #
    # @return [Normalizer] A new normalizer instance
    #
    def initialize(label, input, structure:)
      @label = label
      @input = input
      @structure = structure
    end

    #
    # Normalizes the data according to the defined structure
    #
    # @return [Array<Hash, Set>] The normalized data and any errors
    #
    def normalize
      case @input
      when Hash
        normalize_hash
      when Array
        normalize_array
      end
    end

    private

    #
    # Extracts a value from a hash checking multiple keys
    #
    # @param hash [Hash] The hash to extract from
    # @param keys [Array<String, String>] The keys to check
    #
    # @return [Object, nil] The value if found, nil otherwise
    #
    # @private
    #
    def value_from_keys(hash, keys)
      hash.find { |k, v| keys.include?(k.to_s) }&.second
    end

    #
    # Checks if a value is of the expected type
    #
    # @param value [Object] The value to check
    # @param expected_type [Class, Array<Class>] The expected type(s)
    # @param nilable [Boolean] Allow nil values
    #
    # @return [Boolean] Whether the value is of the expected type
    #
    # @private
    #
    def valid_class?(value, expected_type, nilable: false)
      if expected_type.instance_of?(Array)
        expected_type.any? { |type| value.is_a?(type) }
      else
        (nilable && value.nil?) || value.is_a?(expected_type)
      end
    end

    #
    # Generates an error label with information about the key and its aliases
    #
    # Creates a descriptive label for error messages that includes the key name,
    # any aliases it may have, and the context in which it appears.
    #
    # @param key [Symbol, String] The key that caused the error
    # @param aliases [Array<Symbol, String>] Any aliases for the key
    #
    # @return [String] A formatted error label
    #
    # @example
    #   generate_error_label(:user_id, [:id, :uid])
    #   # => "\"user_id\" (aliases \"id\", \"uid\") in user config"
    #
    def generate_error_label(key, aliases)
      error_label = key.to_s.in_quotes

      if aliases.size > 0
        aliases = aliases.join_map(", ") { |a| a.to_s.in_quotes }
        error_label += " (aliases #{aliases})"
      end

      error_label + " in #{@label}"
    end

    def replace_references(attributes, references)
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
          result = replace_references(attribute.slice(:structure), references)
          attribute.merge!(result)
        elsif [Hash, "hash"].include?(attribute[:type])
          replace_references(attribute[:structure], references)
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

    #
    # Normalizes a hash according to the structure definition
    #
    # Processes each key-value pair in the input hash according to the corresponding
    # definition in the structure. Handles both explicitly defined keys and wildcard
    # keys (specified with "*") that apply to any keys not otherwise defined.
    #
    # @return [Array<Hash, Set>] A two-element array containing:
    #   1. The normalized hash with validated and transformed values
    #   2. A set of any errors encountered during normalization
    #
    # @example Normalizing a hash with explicit definitions
    #   structure = {name: {type: String}, age: {type: Integer}}
    #   input = {name: "John", age: "25"}
    #   normalize_hash # => [{name: "John", age: 25}, #<Set: {}>]
    #
    # @private
    #
    def normalize_hash
      output, errors = {}, Set.new

      @structure.each do |key, definition|
        # Skip the wildcard key if it exists, handled below
        next if key == :* || key == "*"

        continue, value = normalize_attribute(key, definition, errors:)
        next unless continue

        output[key] = value
      rescue => e
        errors << e
      end

      # A wildcard will normalize the rest of the keys in the input
      wildcard_structure = @structure[:*] || @structure["*"]

      if wildcard_structure.present?
        # We need to determine which keys we need to check
        structure_keys = (@structure.keys + @structure.values.key_map(:aliases))
          .compact
          .flatten
          .map(&:to_sym)

        # Once we have which keys the structure used, we can get the remaining keys
        keys_to_normalize = (@input.keys - structure_keys)

        # They are checked against the wildcard's structure
        keys_to_normalize.each do |key|
          continue, value = normalize_attribute(key, wildcard_structure, errors:)
          next unless continue

          output[key] = value
        rescue => e
          errors << e
        end
      end

      [output, errors]
    end

    #
    # Normalizes a single attribute according to its definition
    #
    # Validates the attribute against its type constraints, applies default values,
    # runs custom validators, and recursively processes nested structures.
    #
    # @param key [Symbol, String] The attribute key to normalize
    # @param definition [Hash] The definition specifying rules for the attribute
    # @param errors [Set] A set to collect any errors encountered
    #
    # @return [Array<Boolean, Object>] A two-element array containing:
    #   1. Boolean indicating if the attribute should be included in output
    #   2. The normalized attribute value (if first element is true)
    #
    # @example Normalizing a simple attribute
    #   key = :name
    #   definition = {type: String, required: true}
    #   normalize_attribute(key, definition, errors: Set.new)
    #   # => [true, "John"]
    #
    # @private
    #
    def normalize_attribute(key, definition, errors:)
      has_default = definition.key?(:default)

      type_class = definition[:type]
      aliases = definition[:aliases] || []
      default = definition[:default]
      required = definition[:required] == true

      # Get the value
      value = value_from_keys(@input, [key.to_s] + aliases)

      # Drop the key if needed
      return [false] if value.nil? && !has_default && !required

      # Default the value if needed
      value = default.dup if has_default && value.nil?

      error_label = generate_error_label(key, aliases)

      # Type + existence check
      if !valid_class?(value, type_class, nilable: has_default)
        if (line_number = @input[:line_number])
          error_label += " (line #{line_number})"
        end

        raise Error::InvalidTypeError.new(value, type_class, for: error_label)
      end

      # Call the validator if it has one
      if (name = definition[:validator]) && name.present?
        Validators.call(name, value, label: error_label)
      end

      # Normalize any sub structures
      if (substructure = definition[:structure]) && substructure.present?
        value = normalize_substructure(error_label, value, substructure, errors)
      end

      [true, value]
    end

    #
    # Normalizes a nested substructure within a parent structure
    #
    # Recursively processes nested Hash or Array structures according to
    # their structure definitions, collecting any validation errors.
    #
    # @param new_label [String] The label to use for error messages
    # @param value [Hash, Array] The nested structure to normalize
    # @param substructure [Hash] The structure definition for validation
    # @param errors [Set] A set to collect any encountered errors
    #
    # @return [Hash, Array] The normalized substructure
    #
    # @example
    #   value = {name: "Test", age: "25"}
    #   substructure = {name: {type: String}, age: {type: Integer}}
    #   normalize_substructure("user", value, substructure, Set.new)
    #   # => {name: "Test", age: 25}
    #
    def normalize_substructure(new_label, value, substructure, errors)
      if substructure.is_a?(Proc)
        return substructure.call(value, errors:, label: @label)
      end

      return value unless value.is_a?(Hash) || value.is_a?(Array)

      new_value, new_errors = self.class
        .new(new_label, value, structure: substructure)
        .normalize

      errors.merge(new_errors) if new_errors.size > 0
      new_value
    end

    #
    # Normalizes an array according to its structure definition
    #
    # Processes each element in the input array, validating its type and
    # recursively normalizing any nested structures.
    #
    # @return [Array<Object, Set>] A two-element array containing:
    #   1. The normalized array
    #   2. A set of any errors encountered during normalization
    #
    # @example
    #   input = [1, "string", 3]
    #   structure = {type: Numeric}
    #   normalize_array # => [[1, 3], #<Set: {Error}>]
    #
    def normalize_array
      output, errors = [], Set.new

      @input.each_with_index do |value, index|
        type_class = @structure[:type]
        error_label = "index #{index} of #{@label}"

        if !valid_class?(value, type_class)
          raise Error::InvalidTypeError.new(value, type_class, for: error_label)
        end

        # Call the validator if it has one
        if (name = @structure[:validator]) && name.present?
          Validators.call(name, value, label: error_label)
        end

        if (substructure = @structure[:structure])
          value = normalize_substructure(error_label, value, substructure, errors)
        end

        output << value
      rescue => e
        errors << e
      end

      [output, errors]
    end

    # Define the normalizers
    load_from_files
  end
end
