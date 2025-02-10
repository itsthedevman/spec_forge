# frozen_string_literal: true

module SpecForge
  class Normalizer
    class Factory < Normalizer
      STRUCTURE = {
        model_class: {
          type: String,
          aliases: %i[class],
          default: ""
        },
        variables: Normalizer::SHARED_ATTRIBUTES[:variables],
        attributes: {
          type: Hash,
          default: {}
        }
      }.freeze
    end

    # On Normalizer
    class << self
      #
      # Generates an empty factory hash
      #
      # @return [Hash]
      #
      def default_factory
        Factory.default
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
        raise InvalidTypeError.new(factory, Hash, for: "factory") unless Type.hash?(factory)

        Normalizer::Factory.new("factory", factory).normalize
      end
    end
  end
end
