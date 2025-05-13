# frozen_string_literal: true

module SpecForge
  module Documentation
    module OpenAPI
      module V3_0 # standard:disable Naming/ClassAndModuleCamelCase
        class Tag
          attr_reader :name, :description, :external_docs

          def initialize(name, data)
            @name = name.to_s

            case data
            when String
              @description = data
            when Hash
              @description = data[:description]
              @external_docs = data[:external_docs]
            end
          end

          def to_h
            {
              name:,
              description:,
              externalDocs:
            }
          end

          alias_method :externalDocs, :external_docs
        end
      end
    end
  end
end
