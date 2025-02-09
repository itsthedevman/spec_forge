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
      content_type: {
        type: String,
        aliases: %i[type],
        default: ""
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
      }
    }.freeze

    STRUCTURE = {}

    class << self
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
      # @private
      #
      def default
        new("", "").default
      end
    end

    attr_reader :label, :input, :structure

    def initialize(label, input, structure: self.class::STRUCTURE)
      @label = label
      @input = input
      @structure = structure
    end

    def normalize
      normalize_to_structure
    end

    def default
      structure.transform_values do |value|
        if (default = value[:default])
          default.dup
        elsif value[:type] == Integer # Can't call new on int
          0
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
          raise InvalidTypeError.new(value, type_class, for: "\"#{key}\" on #{label}")
        end

        value =
          case sub_structure
          when Hash
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

#######################################################################
# These need to be required after the base class due to them requiring
# a constant
require_relative "normalizer/config"
require_relative "normalizer/constraint"
require_relative "normalizer/expectation"
require_relative "normalizer/factory_reference"
require_relative "normalizer/factory"
require_relative "normalizer/spec"
