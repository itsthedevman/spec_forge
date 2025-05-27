# frozen_string_literal: true

module SpecForge
  module Documentation
    module OpenAPI
      module V3_0 # standard:disable Naming/ClassAndModuleCamelCase
        class Response < OpenAPI::Base
          def to_h
            {
              # Required
              description:,
              content:
            }.merge_compact(
              # Optional
              headers:,
              links:
            )
          end

          def description
            documentation[:description] || ""
          end

          def content
            schema = Schema.new(type: document.body.type).to_h

            {
              document.content_type => MediaType.new(schema:).to_h
            }.deep_merge(documentation)
          end

          def headers
            docs = documentation[:headers] || {}

            document.headers
              .merge(docs)
              .presence
          end

          def links
            documentation[:links].presence
          end
        end
      end
    end
  end
end
