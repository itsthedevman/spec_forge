# frozen_string_literal: true

module SpecForge
  class Normalizer
    class Expectation < Normalizer
      STRUCTURE = {
        # Internal
        id: Normalizer::SHARED_ATTRIBUTES[:id],
        line_number: Normalizer::SHARED_ATTRIBUTES[:line_number],

        # User defined
        name: {type: String, default: ""},
        base_url: Normalizer::SHARED_ATTRIBUTES[:base_url],
        url: Normalizer::SHARED_ATTRIBUTES[:url],
        http_method: Normalizer::SHARED_ATTRIBUTES[:http_method],
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
      # @return [Hash]
      #
      def default_expectation
        Expectation.default
      end

      #
      # Normalize an array of expectation hashes
      #
      # @raises InvalidStructureError if anything is missing/invalid type
      #
      # @param input [Hash] The hash to normalize
      #
      # @return [Hash] A normalized hash as a new instance
      #
      def normalize_expectations!(input)
        raise_errors! do
          normalize_expectations(input)
        end
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
        if !Type.array?(expectations)
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
    end
  end
end
