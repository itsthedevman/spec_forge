# frozen_string_literal: true

module SpecForge
  module Documentation
    module OpenAPI
      module V3_0 # standard:disable Naming/ClassAndModuleCamelCase
        class Tag < Data.define(:name, :description, :external_docs)
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

          def initialize(name:, description: nil, external_docs: nil)
            super
          end

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
