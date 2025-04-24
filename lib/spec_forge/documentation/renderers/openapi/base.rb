# frozen_string_literal: true

module SpecForge
  module Documentation
    module Renderers
      module OpenAPI
        #
        # Base class for OpenAPI renderers
        #
        # Provides common functionality for OpenAPI renderers of different versions.
        #
        class Base < File
          #
          # Converts the renderer's version to a semantic version object
          #
          # @return [SemVersion] The semantic version
          #
          def self.to_sem_version
            SemVersion.new(CURRENT_VERSION)
          end

          protected

          #
          # Loads OpenAPI configuration from YAML
          #
          # @return [Hash] The normalized OpenAPI configuration
          #
          # @api private
          #
          def config
            @config ||= begin
              path = SpecForge.openapi_path.join("config", "openapi.yml")
              hash = YAML.safe_load_file(path, symbolize_names: true)

              Normalizer.normalize_openapi_config!(hash)
            end
          end

          def parse_user_defined_paths
            path = SpecForge.openapi_path.join("config", "paths", "**", "*.yml")

            paths = Dir[path].map do |path|
              hash = YAML.safe_load_file(path, symbolize_names: true)
              hash.transform_values! { |v| Normalizer.normalize_openapi_path!(v) }
            end

            paths.to_merged_h
          end

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

          #
          # Converts a string to camelCase
          #
          # @param string [String] The string to convert
          #
          # @return [String] The camelCase version of the string
          #
          # @api private
          #
          def camelize(string)
            string.parameterize.underscore.camelcase(:lower)
          end
        end
      end
    end
  end
end
