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
              YAML.safe_load_file(path, symbolize_names: true)
            end
          end

          def parse_user_defined_paths
            path = SpecForge.openapi_path.join("config", "paths", "**", "*.yml")

            paths = Dir[path].map do |path|
              path = Pathname.new(path)
              YAML.safe_load_file(path, symbolize_names: true)
            end

            paths.to_merged_h
          end
        end
      end
    end
  end
end
