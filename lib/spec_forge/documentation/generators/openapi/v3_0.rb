# frozen_string_literal: true

module SpecForge
  module Documentation
    module Generators
      module OpenAPI
        # https://spec.openapis.org/oas/v3.0.4.html
        class V3_0 < Base # standard:disable Naming/ClassAndModuleCamelCase
          #
          # Current OpenAPI 3.0 version supported by this generator
          #
          # @api private
          #
          CURRENT_VERSION = "3.0.4"

          #
          # Alias for OpenAPI V3.0 classes for cleaner code
          #
          # @api private
          #
          OAS = Documentation::OpenAPI::V3_0

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
                OAS::Operation.new(document).to_h
              end
            end
          end
        end
      end
    end
  end
end
