# frozen_string_literal: true

module SpecForge
  class Normalizer
    SHARED_ATTRIBUTES = {
      url: {
        type: String,
        aliases: %i[path],
        default: ""
      },
      http_method: {
        type: String,
        aliases: %i[method],
        default: "GET"
      },
      content_type: {
        type: String,
        aliases: %i[type],
        default: "application/json"
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

    SPEC_STRUCTURE = {
      url: SHARED_ATTRIBUTES[:url],
      http_method: SHARED_ATTRIBUTES[:http_method],
      content_type: SHARED_ATTRIBUTES[:content_type],
      query: SHARED_ATTRIBUTES[:query],
      body: SHARED_ATTRIBUTES[:body],
      variables: SHARED_ATTRIBUTES[:variables],
      expectations: {
        type: Array
      }
    }.freeze

    EXPECTATION_STRUCTURE = {
      url: SHARED_ATTRIBUTES[:url],
      http_method: SHARED_ATTRIBUTES[:http_method],
      content_type: SHARED_ATTRIBUTES[:content_type],
      query: SHARED_ATTRIBUTES[:query],
      body: SHARED_ATTRIBUTES[:body],
      variables: SHARED_ATTRIBUTES[:variables],
      expect: {
        type: Hash
      }
    }.freeze

    CONSTRAINT_STRUCTURE = {
      status: {
        type: Integer
      },
      json: {
        type: Hash,
        default: {}
      }
    }.freeze

    STRUCTURE = {}

    class Spec < Normalizer
      STRUCTURE = Normalizer::SPEC_STRUCTURE
    end

    class Expectation < Normalizer
      STRUCTURE = Normalizer::EXPECTATION_STRUCTURE
    end

    class Constraint < Normalizer
      STRUCTURE = Normalizer::CONSTRAINT_STRUCTURE
    end

    def self.normalize(input)
      output, errors = normalize_spec(input)

      if (expectations = input[:expectations])
        expectation_output, expectation_errors = normalize_expectations(expectations)

        output[:expectations] = expectation_output
        errors += expectation_errors if expectation_errors.size > 0
      end

      raise InvalidStructureError.new(errors) if errors.size > 0

      output
    end

    def self.normalize_spec(spec)
      raise InvalidTypeError.new(spec, Hash, for: "spec") if !spec.is_a?(Hash)

      Normalizer::Spec.new("spec", spec).normalize
    end

    def self.normalize_expectations(expectations)
      if !expectations.is_a?(Array)
        raise InvalidTypeError.new(expectations, Array, for: "\"expectations\" on spec")
      end

      final_errors = []
      final_output = expectations.map.with_index do |expectation, index|
        normalizer = Normalizer::Expectation.new("expectation (item #{index})", expectation)
        output, errors = normalizer.normalize

        # If expect is not provided, skip the constraints
        if (constraint = expectation[:expect])
          constraint_output, constraint_errors = Normalizer::Constraint.new(
            "expect (item #{index})", constraint
          ).normalize

          output[:expect] = constraint_output
          errors += constraint_errors if constraint_errors.size > 0
        end

        final_errors += errors if errors.size > 0
        output
      end

      [final_output, final_errors]
    end

    def self.normalize_constraint(constraint)
      raise InvalidTypeError.new(constraint, Hash, for: "expect") if !constraint.is_a?(Hash)

      Normalizer::Constraint.new("expect", constraint).normalize
    end

    attr_reader :label, :input, :structure

    def initialize(label, input)
      @label = label
      @input = input
      @structure = self.class::STRUCTURE
    end

    def normalize
      normalize_to_structure
    end

    protected

    def normalize_to_structure
      output, errors = {}, []

      structure.each do |key, attribute|
        type_class = attribute[:type]
        aliases = attribute[:aliases] || []
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
