# frozen_string_literal: true

module SpecForge
  module Documentation
    module OpenAPI
      module V3_0 # standard:disable Naming/ClassAndModuleCamelCase
        class Schema
          attr_reader :type, :format

          def initialize(options = {})
            @type, @format = transform_type(options[:type])
          end

          def to_h
            {
              type:,
              format:
            }.compact_blank!
          end

          private

          def transform_type(format)
            case format
            when "datetime", "time"
              ["string", "date-time"]
            when "int64", "i64"
              ["integer", "int64"]
            when "int32", "i32"
              ["integer", "int32"]
            when "double", "float"
              ["number", format]
            when "object"
              ["object"]
            when "array"
              ["array"]
            when "boolean", "number", "integer", "string"
              [format]
            else
              ["string", format]
            end
          end
        end
      end
    end
  end
end
