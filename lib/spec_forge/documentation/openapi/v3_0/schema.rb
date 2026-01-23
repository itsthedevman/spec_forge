# frozen_string_literal: true

module SpecForge
  module Documentation
    module OpenAPI
      class V30
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
          # The schema content (for arrays/objects)
          #
          # @return [Object, nil] The schema content
          #
          attr_reader :content

          #
          # Creates a new OpenAPI schema object
          #
          # @param options [Hash] Schema configuration options
          # @option options [String] :type The data type to convert to OpenAPI format
          # @option options [Object] :content The content/items for arrays or properties for objects
          #
          # @return [Schema] A new schema instance
          #
          def initialize(options = {})
            @type, @format = transform_type(options[:type])
            @content = options[:content]
          end

          #
          # Converts the schema to an OpenAPI-compliant hash
          #
          # @return [Hash] OpenAPI-formatted schema object
          #
          def to_h
            base = {
              type:,
              format:
            }.compact_blank!

            # Add items for arrays
            if type == "array" && content.present?
              # Content is an array like [{type: "string"}], take first element as items schema
              items_type = content.first&.dig(:type) || "object"
              base[:items] = { type: items_type }
            end

            base
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
