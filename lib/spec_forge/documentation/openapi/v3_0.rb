# frozen_string_literal: true

module SpecForge
  module Documentation
    module OpenAPI
      # https://spec.openapis.org/oas/v3.0.4.html
      class V30 < Generator
        #
        # Current OpenAPI 3.0 version supported by this generator
        #
        # @api private
        #
        CURRENT_VERSION = "3.0.4"

        #
        # Validates an OpenAPI specification against the standard
        #
        # Uses the openapi3_parser gem to validate the generated specification
        # and provides detailed error reporting if validation fails.
        #
        # @param output [Hash] The OpenAPI specification to validate
        #
        # @return [void]
        #
        # @raise [Error::InvalidOASDocument] If the specification is invalid
        #
        def self.validate!(output)
          document = Openapi3Parser.load(output)
          if document.valid?
            puts "✅ No validation errors found!"
            return
          end

          puts ErrorFormatter.format(document.errors.errors)
          raise Error::InvalidOASDocument
        end

        #
        # Generates an OpenAPI 3.0 specification from the input document
        #
        # Creates a complete OpenAPI specification by combining the document's
        # endpoint data with configuration files and ensuring compliance with
        # OpenAPI 3.0.4 standards.
        #
        # @return [Hash] Complete OpenAPI 3.0 specification
        #
        def generate
          output = {
            openapi: CURRENT_VERSION,
            paths:
          }

          output.deep_stringify_keys!
          output.deep_merge!(config)

          output
        end

        #
        # Transforms document endpoints into OpenAPI paths structure
        #
        # Converts the internal endpoint representation into the OpenAPI paths
        # format, with each path containing operations organized by HTTP method.
        #
        # @return [Hash] OpenAPI paths object with operations
        #
        def paths
          paths = input.endpoints.deep_dup

          paths.each do |path, operations|
            operations.transform_values! do |document|
              Operation.new(document).to_h
            end
          end
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
