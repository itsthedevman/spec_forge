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

              Normalizer.normalize!(hash, using: :openapi_config)
            end
          end

          def parse_user_defined_paths
            path = SpecForge.openapi_path.join("config", "paths", "**", "*.yml")
            version = self.class.to_sem_version.morph { |v| "#{v.major}.#{v.minor}" }

            paths = Dir[path].map do |path|
              path = Pathname.new(path)

              label = path.relative_path_from(SpecForge.openapi_path)
              hash = YAML.safe_load_file(path, symbolize_names: true)

              hash.transform_values! do |value|
                Normalizer.normalize!(value, using: "openapi/v#{version}/path_item", label:)
              end
            end

            paths.to_merged_h
          end
        end
      end
    end
  end
end
