# frozen_string_literal: true

module SpecForge
  module Documentation
    module Renderers
      module OpenAPI
        class Base < File
          def self.to_sem_version
            SemVersion.new(CURRENT_VERSION)
          end

          protected

          def type_to_schema(format, content: nil)
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
              {type: "object", properties: content || {}}
            when "array"
              {type: "array", items: content || []}
            when "boolean", "number", "integer", "string"
              {type: format}
            else
              {type: "string", format:}
            end
          end

          def camelize(string)
            string.parameterize.underscore.camelcase(:lower)
          end
        end
      end
    end
  end
end
