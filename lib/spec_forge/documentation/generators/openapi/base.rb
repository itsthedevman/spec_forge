# frozen_string_literal: true

module SpecForge
  module Documentation
    module Generators
      module OpenAPI
        #
        # Base class for OpenAPI generators
        #
        # Provides common functionality for OpenAPI generators of different versions.
        #
        class Base < Generators::Base
          #
          # Converts the generator's version to a semantic version object
          #
          # @return [SemVersion] The semantic version
          #
          def self.to_sem_version
            SemVersion.new(CURRENT_VERSION)
          end

          def self.generate(use_cache: false)
            document = Documentation::Loader.load_document(use_cache:)
            new(document).generate
          end

          def self.validate!(output)
            document = Openapi3Parser.load(output)
            if document.valid?
              puts "✅ No validation errors found!"
              return
            end

            puts ErrorFormatter.format(document.errors.errors)
            raise Error::InvalidOASDocument
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
              file_extension_glob = "*.{yml,yaml}"
              base_path = SpecForge.openapi_path.join("config")

              root_paths = base_path.join(file_extension_glob)
              path_paths = base_path.join("paths", "**", file_extension_glob)
              component_paths = base_path.join("components", "**", file_extension_glob)

              config = load_yml_from_paths(root_paths).to_merged_h
              paths_config = load_yml_from_paths(path_paths).to_merged_h
              component_config = load_yml_from_paths(component_paths).to_merged_h

              (config["paths"] ||= {}).deep_merge!(paths_config)
              (config["components"] ||= {}).deep_merge!(component_config)

              config
            end
          end

          private

          def load_yml_from_paths(paths)
            Dir[paths].map do |path|
              YAML.safe_load_file(path)
            end
          end
        end
      end
    end
  end
end
