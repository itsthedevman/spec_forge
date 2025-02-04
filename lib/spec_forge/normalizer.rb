# frozen_string_literal: true

module SpecForge
  class Normalizer
    SHARED_ATTRIBUTES = {
      url: {
        type: String,
        aliases: %i[path],
        default: ""
      },
      method: {
        type: String,
        aliases: %i[http_method],
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
      method: SHARED_ATTRIBUTES[:method],
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
      method: SHARED_ATTRIBUTES[:method],
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

    # Go through and convert any aliases to the expected name
    # Convert any attributes to Attribute
    def initialize(user_input)
      @user_input = user_input
    end

    def normalize
      output, errors = {}, []

      normalize_spec(output:, errors:)
      normalize_expectations(output:, errors:)

      raise InvalidStructureError.new(errors) if errors.size > 0

      output
    end

    private

    def normalize_spec(output:, errors:)
      normalize_to_structure(
        @user_input,
        output:, errors:,
        structure: SPEC_STRUCTURE,
        label: "spec"
      )
    end

    def normalize_expectations(output:, errors:)
      input = @user_input[:expectations] || []

      output[:expectations] =
        input.map.with_index do |expectation, index|
          normalized_expectation = {}
          normalized_constraint = {}

          normalize_to_structure(
            expectation,
            output: normalized_expectation,
            errors:,
            structure: EXPECTATION_STRUCTURE,
            label: "expectation (item #{index + 1})"
          )

          normalize_to_structure(
            expectation[:expect],
            output: normalized_constraint,
            errors:,
            structure: CONSTRAINT_STRUCTURE,
            label: "expect"
          )

          # Get around Attribute converting Hash to Literal
          normalized_expectation[:expect] = normalized_constraint
          normalized_expectation
        end
    end

    def normalize_to_structure(input, output:, errors:, structure:, label:)
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
        output[key] = Attribute.from(value)
      rescue => e
        errors << e
      end
    end

    def value_from_keys(hash, keys)
      hash.find { |k, v| v if keys.include?(k) }&.second
    end
  end
end
