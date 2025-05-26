# frozen_string_literal: true

module SpecForge
  module Documentation
    module OpenAPI
      module V3_0 # standard:disable Naming/ClassAndModuleCamelCase
        class Response < OpenAPI::Base
          def to_h
            schema = Schema.new(type: document.body.type, content: document.body.content).to_h

            {
              description: documentation[:description],
              content: {
                document.content_type => {schema:}
              }.merge(documentation)
            }.merge_compact(
              headers: document.headers.merge(documentation[:headers]).presence,
              links: documentation[:links].presence
            )
          end
        end
      end
    end
  end
end
