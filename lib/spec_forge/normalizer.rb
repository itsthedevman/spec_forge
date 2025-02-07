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

    class Spec < Normalizer
      STRUCTURE = {
        base_url: SHARED_ATTRIBUTES[:base_url],
        url: SHARED_ATTRIBUTES[:url],
        http_method: SHARED_ATTRIBUTES[:http_method],
        content_type: SHARED_ATTRIBUTES[:content_type],
        query: SHARED_ATTRIBUTES[:query],
        body: SHARED_ATTRIBUTES[:body],
        variables: SHARED_ATTRIBUTES[:variables],
        expectations: {type: Array}
      }.freeze
    end

    class Expectation < Normalizer
      STRUCTURE = {
        name: {type: String, default: ""},
        base_url: SHARED_ATTRIBUTES[:base_url],
        url: SHARED_ATTRIBUTES[:url],
        http_method: SHARED_ATTRIBUTES[:http_method],
        content_type: SHARED_ATTRIBUTES[:content_type],
        query: SHARED_ATTRIBUTES[:query],
        body: SHARED_ATTRIBUTES[:body],
        variables: SHARED_ATTRIBUTES[:variables],
        expect: {type: Hash}
      }.freeze
    end

    class Constraint < Normalizer
      STRUCTURE = {
        status: {
          type: Integer
        },
        json: {
          type: Hash,
          default: {}
        }
      }.freeze
    end

    class Factory < Normalizer
      STRUCTURE = {
        model_class: {
          type: String,
          aliases: %i[class],
          default: ""
        },
        variables: SHARED_ATTRIBUTES[:variables],
        attributes: {
          type: Hash,
          default: {}
        }
      }.freeze
    end

    class Config < Normalizer
      STRUCTURE = {
        base_url: {type: String},
        authorization: {
          type: Hash,
          default: {
            # Default is a key on this hash
            default: {header: "", value: ""}
          },
          content: {
            default: {
              type: Hash,
              default: {
                header: {type: String},
                value: {type: String}
              }
            }
          }
        }
      }.freeze
    end

    class << self
      #
      # Generates an empty spec hash
      #
      # @return [Hash]
      #
      def default_spec
        Spec.default
      end

      #
      # Generates an empty expectation hash
      #
      # @return [Hash]
      #
      def default_expectation
        Expectation.default
      end

      #
      # Generates an empty constraint hash
      #
      # @return [Hash]
      #
      def default_constraint
        Constraint.default
      end

      #
      # Generates an empty factory hash
      #
      # @return [Hash]
      #
      def default_factory
        Factory.default
      end

      #
      # Generates an empty config hash
      #
      # @return [Hash]
      #
      def default_config
        Config.default
      end

      #
      # Normalizes a factory hash by standardizing its keys while ensuring the required data
      # is provided or defaulted.
      # Raises InvalidStructureError if anything is missing/invalid type
      #
      # @param input [Hash] The hash to normalize
      #
      # @return [Hash] A normalized hash as a new instance
      #
      def normalize_factory!(input)
        raise_errors! do
          normalize_factory(input)
        end
      end

      #
      # Normalizes a config hash by standardizing its keys while ensuring the required data
      # is provided or defaulted.
      # Raises InvalidStructureError if anything is missing/invalid type
      #
      # @param input [Hash] The hash to normalize
      #
      # @return [Hash] A normalized hash as a new instance
      #
      def normalize_config!(input)
        raise_errors! do
          normalize_config(input)
        end
      end

      #
      # Normalizes a complete spec hash by standardizing its keys while ensuring the required data
      # is provided or defaulted.
      # Raises InvalidStructureError if anything is missing/invalid type
      #
      # @param input [Hash] The hash to normalize
      #
      # @return [Hash] A normalized hash as a new instance
      #
      def normalize_spec!(input)
        raise_errors! do
          output, errors = normalize_spec(input)

          # Process expectations
          if (expectations = input[:expectations]) && expectations.is_a?(Array)
            expectation_output, expectation_errors = normalize_expectations(expectations)

            output[:expectations] = expectation_output
            errors += expectation_errors if expectation_errors.size > 0
          end

          [output, errors]
        end
      end

      #
      # Normalize a spec hash
      # Used internally by .normalize_spec, but is available for utility
      #
      # @param spec [Hash] Spec representation as a Hash
      #
      # @return [Array] Two item array
      #   First - The normalized hash
      #   Second - Array of errors, if any
      #
      # @private
      #
      def normalize_spec(spec)
        raise InvalidTypeError.new(spec, Hash, for: "spec") if !spec.is_a?(Hash)

        Normalizer::Spec.new("spec", spec).normalize
      end

      #
      # Normalize an array of expectation hashes
      # Used internally by .normalize_spec, but is available for utility
      #
      # @param expectations [Array<Hash>] An array of expectation hashes
      #
      # @return [Array] Two item array
      #   First - The normalized Array<Hash>
      #   Second - Array of errors, if any
      #
      # @private
      #
      def normalize_expectations(expectations)
        if !expectations.is_a?(Array)
          raise InvalidTypeError.new(expectations, Array, for: "\"expectations\" on spec")
        end

        final_errors = Set.new
        final_output = expectations.map.with_index do |expectation, index|
          normalizer = Normalizer::Expectation.new("expectation (item #{index})", expectation)
          output, errors = normalizer.normalize

          # If expect is not provided, skip the constraints
          if (constraint = expectation[:expect])
            constraint_output, constraint_errors = Normalizer::Constraint.new(
              "expect (item #{index})", constraint
            ).normalize

            output[:expect] = constraint_output
            errors.merge(constraint_errors) if constraint_errors.size > 0
          end

          final_errors.merge(errors) if errors.size > 0
          output
        end

        [final_output, final_errors]
      end

      #
      # Normalize a constraint hash
      # Used internally by .normalize_spec, but is available for utility
      #
      # @param constraint [Hash] Constraint representation as a Hash
      #
      # @return [Array] Two item array
      #   First - The normalized hash
      #   Second - Array of errors, if any
      #
      # @private
      #
      def normalize_constraint(constraint)
        raise InvalidTypeError.new(constraint, Hash, for: "expect") if !constraint.is_a?(Hash)

        Normalizer::Constraint.new("expect", constraint).normalize
      end

      #
      # Normalize a factory hash
      # Used internally by .normalize_factory, but is available for utility
      #
      # @param factory [Hash] Factory representation as a Hash
      #
      # @return [Array] Two item array
      #   First - The normalized hash
      #   Second - Array of errors, if any
      #
      # @private
      #
      def normalize_factory(factory)
        raise InvalidTypeError.new(factory, Hash, for: "factory") if !factory.is_a?(Hash)

        Normalizer::Factory.new("factory", factory).normalize
      end

      #
      # Normalize a config hash
      # Used internally by .normalize_config, but is available for utility
      #
      # @param config [Hash] Configuration representation as a Hash
      #
      # @return [Array] Two item array
      #   First - The normalized hash
      #   Second - Array of errors, if any
      #
      # @private
      #
      def normalize_config(config)
        raise InvalidTypeError.new(config, Hash, for: "config") if !config.is_a?(Hash)

        Normalizer::Config.new("config", config).normalize
      end

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
        if !value.is_a?(type_class)
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
      hash.find { |k, v| v if keys.include?(k) }&.second
    end
  end
end
