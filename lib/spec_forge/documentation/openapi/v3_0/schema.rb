# frozen_string_literal: true

module SpecForge
  module Documentation
    module OpenAPI
      module V3_0 # standard:disable Naming/ClassAndModuleCamelCase
        class Schema
          def self.from_document(document)
          end

          def initialize(options = {})
            @type = options[:type]
          end

          private

          #
          # Converts a type string to an OpenAPI schema object
          #
          # @param format [String] Type format string
          #
          # @return [Hash] OpenAPI schema definition
          #
          # @api private
          #
          def type_to_schema(format)
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

          #
          # Converts content to an OpenAPI schema object
          #
          # @param content [Hash, Array] The content to convert
          #
          # @return [Hash] OpenAPI schema properties or items
          #
          # @api private
          #
          def content_to_schema(content)
            case content
            when Hash
              {properties: content}
            when Array
              {items: content}
            else
              {}
            end
          end
        end
      end
    end
  end
end
