# frozen_string_literal: true

module SpecForge
  class Normalizer
    class Spec < Normalizer
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
      # @return [Hash]
      #
      def default_spec
        Spec.default
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
      def normalize_spec(spec, label: "spec")
        raise InvalidTypeError.new(spec, Hash, for: label) unless Type.hash?(spec)

        Normalizer::Spec.new(label, spec).normalize
      end
    end
  end
end
