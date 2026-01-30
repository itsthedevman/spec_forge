# frozen_string_literal: true

module SpecForge
  module Documentation
    module OpenAPI
      class V30
        #
        # Represents an OpenAPI 3.0 Tag object
        #
        # Handles tag definitions for categorizing and organizing API operations
        # with optional descriptions and external documentation links.
        #
        # @see https://spec.openapis.org/oas/v3.0.4.html#tag-object
        #
        class Tag < Data.define(:name, :description, :external_docs)
          #
          # Creates a tag object from name and data
          #
          # Handles both string descriptions and hash configurations with
          # external documentation references.
          #
          # @param name [String, Symbol] The tag name
          # @param data [String, Hash] Either a description string or full config hash
          #
          # @return [Tag] A new tag instance
          #
          def self.parse(name, data)
            name = name.to_s

            case data
            when String
              description = data
            when Hash
              description = data[:description]
              external_docs = data[:external_docs]
            end

            new(name:, description:, external_docs:)
          end

          #
          # Creates a new OpenAPI tag object
          #
          # @param name [String] The tag name
          # @param description [String, nil] Optional tag description
          # @param external_docs [Hash, nil] Optional external documentation reference
          #
          # @return [Tag] A new tag instance
          #
          def initialize(name:, description: nil, external_docs: nil)
            super
          end

          #
          # Converts the tag to an OpenAPI-compliant hash
          #
          # Transforms internal attribute names to match OpenAPI specification
          # and removes any blank values for clean output.
          #
          # @return [Hash] OpenAPI-formatted tag object
          #
          def to_h
            super
              .rename_key_unordered!(:external_docs, :externalDocs)
              .compact_blank!
          end
        end
      end
    end
  end
end
