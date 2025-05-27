# frozen_string_literal: true

module SpecForge
  module Documentation
    module OpenAPI
      module V3_0 # standard:disable Naming/ClassAndModuleCamelCase
        class Example < Data.define(:summary, :description, :value, :external_value)
          def initialize(summary: nil, description: nil, value: nil, external_value: nil)
            super
          end

          def to_h
            super
              .rename_key_unordered!(:external_value, :externalValue)
              .compact_blank
          end
        end
      end
    end
  end
end
