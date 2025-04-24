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

      define_normalizer_methods(self)
    end
  end
end
