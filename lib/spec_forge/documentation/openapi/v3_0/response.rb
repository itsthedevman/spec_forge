# frozen_string_literal: true

module SpecForge
  module Documentation
    module OpenAPI
      class V30
        #
        # Represents an OpenAPI 3.0 Response object
        #
        # Handles response definitions including status descriptions, content types,
        # headers, and links for OpenAPI specifications.
        #
        # @see https://spec.openapis.org/oas/v3.0.4.html#response-object
        #
        class Response
          #
          # The document object containing structured API data
          #
          # @return [Object] The document with endpoint information
          #
          attr_reader :document

          #
          # Creates a new Response from a document
          #
          # @param document [Object] The document containing response data
          #
          def initialize(document)
            @document = document
          end

          #
          # Converts the response to an OpenAPI-compliant hash
          #
          # Builds the complete response object with required description and
          # optional content, headers, and links.
          #
          # @return [Hash] OpenAPI-formatted response object
          #
          def to_h
            {
              # Required
              description: "",
              content:
            }.compact_merge(
              # Optional
              headers:
            )
          end

          #
          # Returns content definitions for the response
          #
          # Creates media type objects with schemas and merges with any
          # documentation-provided content definitions.
          #
          # @return [Hash, nil] Content definitions by media type
          #
          def content
            return nil if document.content_type.blank?

            schema = Schema.new(type: document.body.type, content: document.body.content).to_h

            {
              document.content_type => MediaType.new(schema:).to_h
            }
          end

          #
          # Returns header definitions for the response
          #
          # Transforms document headers into OpenAPI format with schema wrappers.
          #
          # @return [Hash, nil] Header definitions
          #
          def headers
            return nil if document.headers.blank?

            document.headers.transform_values do |header|
              {schema: header}
            end
          end
        end
      end
    end
  end
end
