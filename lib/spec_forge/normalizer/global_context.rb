# frozen_string_literal: true

module SpecForge
  class Normalizer
    #
    # Normalizes global context hash structure
    #
    # Ensures that global context definitions have the correct structure
    # and default values for all required settings.
    #
    class GlobalContext < Normalizer
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
        variables: Normalizer::SHARED_ATTRIBUTES[:variables]
      }.freeze
    end

    # On Normalizer
    class << self
      #
      # Generates an empty global context hash
      #
      # @return [Hash] Default global context hash
      #
      def default_global_context
        GlobalContext.default
      end

      #
      # Normalizes a global context hash with validation
      #
      # @param input [Hash] The hash to normalize
      #
      # @return [Hash] A normalized hash with defaults applied
      #
      # @raise [Error::InvalidStructureError] If validation fails
      #
      def normalize_global_context!(input)
        raise_errors! do
          normalize_global_context(input)
        end
      end

      #
      # Normalize a global context hash
      #
      # @param global [Hash] Global context hash
      #
      # @return [Array] [normalized_hash, errors]
      #
      # @private
      #
      def normalize_global_context(global)
        if !Type.hash?(global)
          raise Error::InvalidTypeError.new(global, Hash, for: "global context")
        end

        Normalizer::GlobalContext.new("global context", global).normalize
      end
    end
  end
end
