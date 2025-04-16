# frozen_string_literal: true

module SpecForge
  class Normalizer
    #
    # Normalizes OpenAPI response hash structure for SpecForge
    #
    # Ensures that the configuration has the correct structure
    # and default values for all required settings.
    #
    class OpenapiResponse < Normalizer
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
        description: {type: String}
      }.freeze

      default_label "openapi paths response"

      define_normalizer_methods(self)
    end
  end
end
