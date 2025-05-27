# frozen_string_literal: true

module SpecForge
  module Documentation
    module OpenAPI
      module V3_0 # standard:disable Naming/ClassAndModuleCamelCase
        class Schema
          attr_reader :type

          def initialize(options = {})
            @type = transform_type(options[:type])
          end

          def to_h
            {
              type:
            }
          end

          private

          def transform_type(format)
            case format
            when "datetime", "time"
              {type: "string", format: "date-time"}
            when "int64", "i64"
              {type: "integer", format: "int64"}
            when "int32", "i32"
              {type: "integer", format: "int32"}
            when "double", "float"
              {type: "number", format:}
            when "object"
              {type: "object"}
            when "array"
              {type: "array"}
            when "boolean", "number", "integer", "string"
              {type: format}
            else
              {type: "string", format:}
            end
          end
        end
      end
    end
  end
end
