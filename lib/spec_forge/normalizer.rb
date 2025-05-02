# frozen_string_literal: true

require_relative "normalizer/default"
require_relative "normalizer/definition"
require_relative "normalizer/validators"

module SpecForge
  class Normalizer
    class << self
      attr_reader :structures

      #
      # @api private
      #
      def normalize!(input, using:, label: nil)
        raise_errors! { normalize(input, using:, label:) }
      end

      #
      # @api private
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
      # @api private
      #
      def default(name = nil, structure: nil, include_optional: false)
        structure ||= @structures.dig(name.to_sym, :structure)

        if !structure.is_a?(Hash)
          raise ArgumentError, "Invalid structure. Provide either the name of the structure ('name') or a hash ('structure')"
        end

        default_from_structure(structure, include_optional:)
      end

      #
      # @api private
      #
      def load_from_files
        @structures = Definition.from_files
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

    # @return [String] A label that describes the data itself
    attr_reader :label

    # @return [Hash] The data to normalize
    attr_reader :input

    # @return [Hash] The structure to normalize the data to
    attr_reader :structure

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
      case input
      when Hash
        normalize_hash
      when Array
        normalize_array
      end
    end

    protected

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

      error_label + " in #{label}"
    end

    #
    # Normalizes the input hash according to the structure definition
    #
    # @return [Array<Hash, Set>] Normalized hash and any errors
    #
    # @private
    #
    def normalize_hash
      output, errors = {}, Set.new

      structure.each do |key, attribute|
        has_default = attribute.key?(:default)

        type_class = attribute[:type]
        aliases = attribute[:aliases] || []
        default = attribute[:default]

        # Required by default, unless explicitly set to false.
        # Easier to think of it as !(required == false)
        required = attribute[:required] != false

        # Get the value
        value = value_from_keys(input, [key.to_s] + aliases)

        # Drop the key if needed
        next if value.nil? && !has_default && !required

        # Default the value if needed
        value = default.dup if has_default && value.nil?

        error_label = generate_error_label(key, aliases)

        # Type + existence check
        if !valid_class?(value, type_class, nilable: has_default)
          if (line_number = input[:line_number])
            error_label += " (line #{line_number})"
          end

          raise Error::InvalidTypeError.new(value, type_class, for: error_label)
        end

        # Call the validator if it has one
        if (name = attribute[:validator]) && name.present?
          Validators.call(name, value, label: error_label)
        end

        # Normalize any sub structures
        if (substructure = attribute[:structure]) && substructure.present?
          value = normalize_substructure(error_label, value, substructure, errors)
        end

        # Store the result
        output[key] = value
      rescue => e
        errors << e
      end

      [output, errors]
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
        return substructure.call(value, errors:, label:)
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

      input.each_with_index do |value, index|
        type_class = structure[:type]
        error_label = "index #{index} of #{label}"

        if !valid_class?(value, type_class)
          raise Error::InvalidTypeError.new(value, type_class, for: error_label)
        end

        # Call the validator if it has one
        if (name = structure[:validator]) && name.present?
          Validators.call(name, value, label: error_label)
        end

        if (substructure = structure[:structure])
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
