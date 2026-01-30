# frozen_string_literal: true

module SpecForge
  module Documentation
    module OpenAPI
      class V30
        #
        # Represents an OpenAPI 3.0 Media Type object
        #
        # Handles media type definitions for request and response bodies,
        # including schema definitions, examples, and encoding information.
        #
        # @see https://spec.openapis.org/oas/v3.0.4.html#media-type-object
        #
        class MediaType < Data.define(:schema, :example, :examples, :encoding)
          #
          # Creates a new OpenAPI media type object
          #
          # @param schema [Hash, nil] Schema definition for the media type
          # @param example [Object, nil] Single example value
          # @param examples [Hash, nil] Multiple named examples
          # @param encoding [Hash, nil] Encoding information for the media type
          #
          # @return [MediaType] A new media type instance
          #
          def initialize(schema: nil, example: nil, examples: nil, encoding: nil)
            super
          end

          #
          # Converts the media type to an OpenAPI-compliant hash
          #
          # @return [Hash] OpenAPI-formatted media type object
          #
          def to_h
            super.compact_blank!
          end
        end
      end
    end
  end
end
