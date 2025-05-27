# frozen_string_literal: true

module SpecForge
  module Documentation
    module OpenAPI
      module V3_0 # standard:disable Naming/ClassAndModuleCamelCase
        class MediaType < Data.define(:schema, :example, :examples, :encoding)
          def initialize(schema: nil, example: nil, examples: nil, encoding: nil)
            super
          end

          def to_h
            super.compact_blank!
          end
        end
      end
    end
  end
end
