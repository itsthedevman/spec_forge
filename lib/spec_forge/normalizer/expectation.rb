# frozen_string_literal: true

module SpecForge
  class Normalizer
    #
    # Normalizes expectation hash structure
    #
    # Ensures that expectation definitions have the correct structure
    # and default values for all required settings.
    #
    class Expectation < Normalizer
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
        line_number: Normalizer::SHARED_ATTRIBUTES[:line_number],

        # User defined
        name: Normalizer::SHARED_ATTRIBUTES[:name],
        base_url: Normalizer::SHARED_ATTRIBUTES[:base_url],
        url: Normalizer::SHARED_ATTRIBUTES[:url],
        http_verb: Normalizer::SHARED_ATTRIBUTES[:http_verb],
        headers: Normalizer::SHARED_ATTRIBUTES[:headers],
        query: Normalizer::SHARED_ATTRIBUTES[:query],
        body: Normalizer::SHARED_ATTRIBUTES[:body],
        variables: Normalizer::SHARED_ATTRIBUTES[:variables],
        debug: Normalizer::SHARED_ATTRIBUTES[:debug],
        expect: {type: Hash}
      }.freeze
    end

    # On Normalizer
    class << self
      #
      # Generates an empty expectation hash
      #
      # @return [Hash] Default expectation hash
      #
      def default_expectation
        Expectation.default
      end

      #
      # Normalize an array of expectation hashes
      #
      # @param input [Array<Hash>] The array to normalize
      #
      # @return [Array<Hash>] Normalized array of expectation hashes
      #
      # @raise [Error::InvalidStructureError] If validation fails
      #
      def normalize_expectations!(input)
        raise_errors! do
          normalize_expectations(input)
        end
      end

      #
      # Normalize an array of expectation hashes
      #
      # @param expectations [Array<Hash>] Array of expectation hashes
      #
      # @return [Array] [normalized_array, errors]
      #
      # @private
      #
      def normalize_expectations(expectations)
        if !Type.array?(expectations)
          raise Error::InvalidTypeError.new(expectations, Array, for: "\"expectations\" on spec")
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
    end
  end
end
