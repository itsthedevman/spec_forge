# frozen_string_literal: true

module SpecForge
  module Documentation
    module OpenAPI
      module V30 # standard:disable Naming/ClassAndModuleCamelCase
        #
        # Represents an OpenAPI 3.0 Response object
        #
        # Handles response definitions including status descriptions, content types,
        # headers, and links for OpenAPI specifications.
        #
        # @see https://spec.openapis.org/oas/v3.0.4.html#response-object
        #
        class Response < OpenAPI::Base
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
          # @return [Hash] Content definitions by media type
          #
          def content
            schema = Schema.new(type: document.body.type).to_h

            {
              document.content_type => MediaType.new(schema:).to_h
            }
          end

          #
          # Returns header definitions for the response
          #
          # Merges document headers with documentation-provided headers.
          #
          # @return [Hash, nil] Header definitions
          #
          def headers
            document.headers.presence
          end
        end
      end
    end
  end
end
