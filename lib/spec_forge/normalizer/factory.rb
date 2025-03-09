# frozen_string_literal: true

module SpecForge
  class Normalizer
    #
    # Normalizes factory hash structure
    #
    # Ensures that factory definitions have the correct structure
    # and default values for all required settings.
    #
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
      # @return [Hash] Default factory hash
      #
      def default_factory
        Factory.default
      end

      #
      # Normalizes a factory hash with validation
      #
      # @param input [Hash] The hash to normalize
      #
      # @return [Hash] A normalized hash with defaults applied
      #
      # @raise [InvalidStructureError] If validation fails
      #
      def normalize_factory!(input)
        raise_errors! do
          normalize_factory(input)
        end
      end

      #
      # Normalize a factory hash
      #
      # @param factory [Hash] Factory hash
      #
      # @return [Array] [normalized_hash, errors]
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
