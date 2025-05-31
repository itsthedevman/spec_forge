# frozen_string_literal: true

module SpecForge
  module Documentation
    module OpenAPI
      module V3_0 # standard:disable Naming/ClassAndModuleCamelCase
        #
        # Represents an OpenAPI 3.0 Schema object
        #
        # Handles schema definitions for data types, converting internal type
        # representations to OpenAPI-compliant schema objects.
        #
        # @see https://spec.openapis.org/oas/v3.0.4.html#schema-object
        #
        class Schema
          #
          # The schema type (string, integer, object, etc.)
          #
          # @return [String, nil] The OpenAPI schema type
          #
          attr_reader :type

          #
          # The schema format (date-time, int64, etc.)
          #
          # @return [String, nil] The OpenAPI schema format
          #
          attr_reader :format

          #
          # Creates a new OpenAPI schema object
          #
          # @param options [Hash] Schema configuration options
          # @option options [String] :type The data type to convert to OpenAPI format
          #
          # @return [Schema] A new schema instance
          #
          def initialize(options = {})
            @type, @format = transform_type(options[:type])
          end

          #
          # Converts the schema to an OpenAPI-compliant hash
          #
          # @return [Hash] OpenAPI-formatted schema object
          #
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
