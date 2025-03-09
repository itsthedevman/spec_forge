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
        default: ""
      },
      url: {
        type: String,
        aliases: %i[path],
        default: ""
      },
      http_verb: {
        type: String,
        aliases: %i[method http_method],
        default: "", # Do not default this to "GET". Leave it blank. Seriously.
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
        type: Hash,
        aliases: %i[params],
        default: {}
      },
      body: {
        type: Hash,
        aliases: %i[data],
        default: {}
      },
      variables: {
        type: Hash,
        default: {}
      },
      debug: {
        type: [TrueClass, FalseClass],
        default: false,
        aliases: %i[pry breakpoint]
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
      #
      # Raises any errors collected by the block
      #
      # @yield Block that returns [output, errors]
      # @yieldreturn [Array<Object, Set>] The result and any errors
      #
      # @return [Object] The normalized output if successful
      #
      # @raise [InvalidStructureError] If any errors were encountered
      #
      # @private
      #
      def raise_errors!(&block)
        errors = Set.new

        begin
          output, new_errors = yield
          errors.merge(new_errors) if new_errors.size > 0
        rescue => e
          errors << e
        end

        raise InvalidStructureError.new(errors) if errors.size > 0

        output
      end

      #
      # Returns a default version of this normalizer
      #
      # @return [Hash] Default structure with default values
      #
      # @private
      #
      def default
        new("", "").default
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
      normalize_to_structure
    end

    #
    # Returns a hash with the default structure
    #
    # @return [Hash] A hash with default values for all structure keys
    #
    def default
      structure.transform_values do |value|
        if value.key?(:default)
          value[:default].dup
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
    def normalize_to_structure
      output, errors = {}, Set.new

      structure.each do |key, attribute|
        type_class = attribute[:type]
        aliases = attribute[:aliases] || []
        sub_structure = attribute[:structure]
        default = attribute[:default]
        required = !attribute.key?(:default)

        # Get the value
        value = value_from_keys(input, [key] + aliases)

        # Default the value if needed
        value = default.dup if !required && value.nil?

        # Type + existence check
        if !valid_class?(value, type_class)
          for_context = "\"#{key}\""

          if aliases.size > 0
            aliases = aliases.join_map(", ") { |a| a.to_s.in_quotes }
            for_context += " (aliases #{aliases})"
          end

          for_context += " in #{label}"

          if (line_number = input[:line_number])
            for_context += " (line #{line_number})"
          end

          raise InvalidTypeError.new(value, type_class, for: for_context)
        end

        # Call the validator if it has one
        attribute[:validator]&.call(value)

        # Validate any sub structures
        value =
          case [value.class, sub_structure.class]
          when [Hash, Hash]
            new_value, new_errors = self.class
              .new(label, value, structure: sub_structure)
              .normalize

            errors += new_errors if new_errors.size > 0
            new_value
          else
            value
          end

        # Store
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
  end
end

####################################################################################################
# These need to be required after the base class due to them requiring constants on Normalizer
Dir[File.expand_path("normalizer/*.rb", __dir__)].sort.each do |path|
  require path
end
