# frozen_string_literal: true

module SpecForge
  class Normalizer
    SHARED_ATTRIBUTES = {
      base_url: {
        type: String,
        default: ""
      },
      url: {
        type: String,
        aliases: %i[path],
        default: ""
      },
      http_method: {
        type: String,
        aliases: %i[method],
        default: ""
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

    STRUCTURE = {}

    class << self
      #
      # Raises any errors collected by the block
      #
      # @raises InvalidStructureError
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
      # @private
      #
      def default
        new("", "").default
      end
    end

    attr_reader :label, :input, :structure

    #
    # Creates a normalizer for normalizing Hash data based on a structure
    #
    # @param label [String] A label that describes the data itself
    # @param input [Hash] The data to normalize
    # @param structure [Hash] The structure to normalize the data to
    #
    def initialize(label, input, structure: self.class::STRUCTURE)
      @label = label
      @input = input
      @structure = structure
    end

    #
    # Normalizes the data and returns the result
    #
    # @return [Hash] The normalized data
    #
    def normalize
      normalize_to_structure
    end

    #
    # Returns a hash with the default structure
    #
    # @return [Hash]
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

    def value_from_keys(hash, keys)
      hash.find { |k, v| keys.include?(k) }&.second
    end

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
