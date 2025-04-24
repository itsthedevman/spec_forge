# frozen_string_literal: true

module SpecForge
  #
  # Base class for normalizing various data structures in SpecForge
  #
  # The Normalizer validates and standardizes user input from YAML files,
  # ensuring it meets the expected structure and types before processing.
  # It supports default values, type checking, aliases, and nested structures.
  #
  # @example Normalizing a hash
  #   normalizer = Normalizer.new("spec", input_hash)
  #   output, errors = normalizer.normalize
  #
  class Normalizer
    TYPES = {
      boolean: [TrueClass, FalseClass]
    }.freeze

    #
    # Shared attributes used by the various normalizers
    #
    # @return [Hash<Symbol, Hash>]
    #
    SHARED_ATTRIBUTES = {
      id: {type: String},
      name: {type: String},
      line_number: {type: Integer},
      base_url: {
        type: String,
        default: nil
      },
      url: {
        type: String,
        aliases: %i[path],
        default: nil
      },
      http_verb: {
        type: String,
        aliases: %i[method http_method],
        default: nil, # Do not default this to "GET". Leave it nil. Seriously.
        validator: lambda do |value|
          valid_verbs = HTTP::Verb::VERBS.values
          return if value.blank? || valid_verbs.include?(value.to_s.upcase)

          raise Error, "Invalid HTTP verb: #{value}. Valid values are: #{valid_verbs.join(", ")}"
        end
      },
      headers: {
        type: Hash,
        default: {}
      },
      query: {
        type: [Hash, String],
        aliases: %i[params],
        default: {}
      },
      body: {
        type: [Hash, String],
        aliases: %i[data],
        default: {}
      },
      variables: {
        type: [Hash, String],
        default: {}
      },
      debug: {
        type: TYPES[:boolean],
        default: false,
        aliases: %i[pry breakpoint]
      },
      callback: {
        type: String,
        default: nil,
        validator: lambda do |value|
          return if value.blank?
          return if SpecForge::Callbacks.registered?(value)

          raise Error::UndefinedCallbackError.new(value, SpecForge::Callbacks.registered_names)
        end
      }
    }.freeze

    #
    # Defines the normalized structure for validating and parsing input data
    #
    # Each key represents an attribute with its validation and transformation rules.
    # The structure supports defining:
    # - Expected data type(s)
    # - Default values
    # - Aliases for alternative key names
    # - Optional validation logic
    # - Nested sub-structures
    #
    # @return [Hash] A configuration hash defining attribute validation rules
    #
    # @example Basic structure definition
    #   STRUCTURE = {
    #     name: {
    #       type: String,              # Must be a String
    #       default: "",               # Default to empty string if not provided
    #       aliases: [:title]          # Allows using 'title' as an alternative key
    #     },
    #     age: {
    #       type: Integer,             # Must be an Integer
    #       default: 0                 # Default to 0 if not provided
    #     }
    #   }
    #
    # @see Normalizer
    #
    STRUCTURE = {}

    class << self
      def id
        @id ||= name.split("::").last.underscore
      end

      def label
        @label ||= id.humanize.downcase
      end

      #
      # Sets the default label for this normalizer class
      #
      # @param value [String] The label to use for this normalizer
      #
      # @return [String] The set label
      #
      def default_label(value)
        @label = value
      end

      #
      # Returns a default version of this normalizer
      #
      # @return [Hash] Default structure with default values
      #
      def default
        new("", "").default
      end

      def normalize!(input, label: self.label)
        raise_errors! { normalize(input, label:) }
      end

      #
      # @api private
      #
      def normalize(input, label: self.label)
        raise Error::InvalidTypeError.new(input, Hash, for: label) if !Type.hash?(input)

        new(label, input).normalize
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

      #
      # Defines the standard normalizer methods for a normalizer class
      #
      # This method creates three methods on the Normalizer class for a given normalizer:
      # - default_#{key} - Returns default values for this normalizer
      # - normalize_#{key}! - Normalize with error handling
      # - normalize_#{key} - Normalize without error handling
      #
      # @param normalizer_class [Class] The normalizer class to define methods for
      #
      # @example Defining methods for a spec normalizer
      #   define_normalizer_methods(SpecForge::Normalizer::Spec)
      #   # Creates methods: default_spec, normalize_spec!, normalize_spec
      #
      # @private
      #
      def define_normalizer_methods(normalizer_class)
        name = normalizer_class.id

        Normalizer.define_singleton_method(:"default_#{name}") do
          normalizer_class.default
        end

        Normalizer.define_singleton_method(:"normalize_#{name}!") do |input, **args|
          normalizer_class.normalize!(input, **args)
        end

        Normalizer.define_singleton_method(:"normalize_#{name}") do |input, **args|
          normalizer_class.normalize(input, **args)
        end
      end
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
    def initialize(label, input, structure: self.class::STRUCTURE)
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

    #
    # Returns a hash with the default structure
    #
    # @return [Hash] A hash with default values for all structure keys
    #
    def default
      structure.each_with_object({}) do |(key, value), hash|
        hash[key] =
          if value.key?(:default)
            default = value[:default]
            next if default.nil?

            default.dup
          elsif value[:type] == Integer # Can't call new on int
            0
          elsif value[:type] == Proc # Sameeee
            -> {}
          else
            value[:type].new
          end
      end
    end

    protected

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
        type_class = attribute[:type]
        aliases = attribute[:aliases] || []
        default = attribute[:default]

        has_default = attribute.key?(:default)
        nilable = has_default && default.nil?

        # Get the value
        value = value_from_keys(input, [key] + aliases)
        next if nilable && value.nil?

        # Default the value if needed
        value = default.dup if has_default && value.nil?

        # Type + existence check
        if !valid_class?(value, type_class)
          for_context = generate_error_label(key, aliases)

          if (line_number = input[:line_number])
            for_context += " (line #{line_number})"
          end

          raise Error::InvalidTypeError.new(value, type_class, for: for_context)
        end

        # Call the validator if it has one
        attribute[:validator]&.call(value)

        # Normalize any sub structures
        if (substructure = attribute[:structure])
          new_label = generate_error_label(key, aliases)
          value = normalize_substructure(new_label, value, substructure, errors)
        end

        # Store the result
        output[key] = value
      rescue => e
        errors << e
      end

      [output, errors]
    end

    #
    # Extracts a value from a hash checking multiple keys
    #
    # @param hash [Hash] The hash to extract from
    # @param keys [Array<Symbol, String>] The keys to check
    #
    # @return [Object, nil] The value if found, nil otherwise
    #
    # @private
    #
    def value_from_keys(hash, keys)
      hash.find { |k, v| keys.include?(k) }&.second
    end

    #
    # Checks if a value is of the expected type
    #
    # @param value [Object] The value to check
    # @param expected_type [Class, Array<Class>] The expected type(s)
    #
    # @return [Boolean] Whether the value is of the expected type
    #
    # @private
    #
    def valid_class?(value, expected_type)
      if expected_type.instance_of?(Array)
        expected_type.any? { |type| value.is_a?(type) }
      else
        value.is_a?(expected_type)
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

        if !valid_class?(value, type_class)
          raise Error::InvalidTypeError.new(value, type_class, for: "index #{index} of #{label}")
        end

        # Call the validator if it has one
        structure[:validator]&.call(value)

        if (substructure = structure[:structure])
          value = normalize_substructure("index #{index} of #{label}", value, substructure, errors)
        end

        output << value
      rescue => e
        errors << e
      end

      [output, errors]
    end
  end
end

####################################################################################################
# These need to be required after the base class due to them requiring constants on Normalizer
Dir[File.expand_path("normalizer/*.rb", __dir__)].sort.each do |path|
  require path
end
