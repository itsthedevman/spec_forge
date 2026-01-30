# frozen_string_literal: true

module SpecForge
  module Documentation
    module OpenAPI
      class V30
        #
        # Represents an OpenAPI 3.0 Example object
        #
        # Creates example objects for request/response documentation with
        # optional summary, description, and external reference support.
        #
        # @see https://spec.openapis.org/oas/v3.0.4.html#example-object
        #
        class Example < Data.define(:summary, :description, :value, :external_value)
          #
          # Creates a new OpenAPI example object
          #
          # @param summary [String, nil] Brief summary of the example's purpose
          # @param description [String, nil] Detailed description of the example
          # @param value [Object, nil] The actual example value
          # @param external_value [String, nil] URL pointing to the example value
          #
          # @return [Example] A new example instance
          #
          def initialize(summary: nil, description: nil, value: nil, external_value: nil)
            super
          end

          #
          # Converts the example to an OpenAPI-compliant hash
          #
          # @return [Hash] OpenAPI-formatted example object
          #
          def to_h
            super
              .rename_key_unordered!(:external_value, :externalValue)
              .compact_blank!
          end
        end
      end
    end
  end
end
