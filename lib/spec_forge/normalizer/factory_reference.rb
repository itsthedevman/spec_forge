# frozen_string_literal: true

module SpecForge
  class Normalizer
    #
    # Normalizes factory reference hash structure
    #
    # Ensures that factory references have the correct structure
    # and default values for all required settings.
    #
    class FactoryReference < Normalizer
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
        attributes: {
          type: Hash,
          default: {}
        },
        build_strategy: {
          type: String,
          aliases: %i[strategy],
          default: "create"
        },
        size: {
          type: Integer,
          aliases: %i[count],
          default: 0
        }
      }.freeze

      define_normalizer_methods(self)
    end
  end
end
