# frozen_string_literal: true

module SpecForge
  class Normalizer
    #
    # Normalizes spec hash structure
    #
    # Ensures that spec definitions have the correct structure
    # and default values for all required settings.
    #
    class Spec < Normalizer
      #
      # Defines the normalized structure for configuration validation
      #
      # Specifies validation rules for configuration attributes:
      # - Enforces specific data types
      # - Provides default values
      # - Supports alternative key names
      #
      # @return [Hash] Configuration attribute validation rules
      #
      STRUCTURE = {
        # Internal
        id: Normalizer::SHARED_ATTRIBUTES[:id],
        name: Normalizer::SHARED_ATTRIBUTES[:name],
        file_name: {type: String},
        file_path: {type: String},
        line_number: Normalizer::SHARED_ATTRIBUTES[:line_number],

        # User defined
        base_url: Normalizer::SHARED_ATTRIBUTES[:base_url],
        url: Normalizer::SHARED_ATTRIBUTES[:url],
        http_verb: Normalizer::SHARED_ATTRIBUTES[:http_verb],
        headers: Normalizer::SHARED_ATTRIBUTES[:headers],
        query: Normalizer::SHARED_ATTRIBUTES[:query],
        body: Normalizer::SHARED_ATTRIBUTES[:body],
        variables: Normalizer::SHARED_ATTRIBUTES[:variables],
        debug: Normalizer::SHARED_ATTRIBUTES[:debug],
        expectations: {type: Array}
      }.freeze
    end

    # On Normalizer
    class << self
      #
      # Generates an empty spec hash
      #
      # @return [Hash] Default spec hash
      #
      def default_spec
        Spec.default
      end

      #
      # Normalizes a spec hash with validation and processes expectations
      #
      # @param input [Hash] The hash to normalize
      # @param label [String] Label for error messages
      #
      # @return [Hash] A normalized hash with defaults applied
      #
      # @raise [InvalidStructureError] If validation fails
      #
      def normalize_spec!(input, label: "spec")
        raise_errors! do
          output, errors = normalize_spec(input, label:)

          # Process expectations
          if (expectations = input[:expectations]) && Type.array?(expectations)
            expectation_output, expectation_errors = normalize_expectations(expectations)

            output[:expectations] = expectation_output
            errors += expectation_errors if expectation_errors.size > 0
          end

          [output, errors]
        end
      end

      #
      # Normalize a spec hash
      #
      # @param spec [Hash] Spec hash
      # @param label [String] Label for error messages
      #
      # @return [Array] [normalized_hash, errors]
      #
      # @private
      #
      def normalize_spec(spec, label: "spec")
        raise InvalidTypeError.new(spec, Hash, for: label) unless Type.hash?(spec)

        Normalizer::Spec.new(label, spec).normalize
      end
    end
  end
end
