# frozen_string_literal: true

module SpecForge
  class Normalizer
    #
    # Normalizes configuration hash structure for SpecForge
    #
    # Ensures that the global configuration has the correct structure
    # and default values for all required settings.
    #
    class Configuration < Normalizer
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
        base_url: SHARED_ATTRIBUTES[:base_url].except(:default), # Make it required
        headers: SHARED_ATTRIBUTES[:headers],
        query: SHARED_ATTRIBUTES[:query],
        factories: {
          type: Hash,
          default: {},
          structure: {
            auto_discover: {
              type: [TrueClass, FalseClass],
              default: true
            },
            paths: {
              type: Array,
              default: []
            }
          }
        },
        on_debug: {
          type: Proc
        }
      }.freeze

      define_normalizer_methods(self)
    end
  end
end
