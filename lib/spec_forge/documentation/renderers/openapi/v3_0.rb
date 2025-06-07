# frozen_string_literal: true

module SpecForge
  module Documentation
    module Renderers
      module OpenAPI
        # https://spec.openapis.org/oas/v3.0.4.html
        class V3_0 < Base # standard:disable Naming/ClassAndModuleCamelCase
          #
          # Current OpenAPI 3.0 version supported by this renderer
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

          def render
            output = {
              openapi: CURRENT_VERSION,
              paths:
            }

            output.deep_stringify_keys!
            output.deep_merge!(config)

            output
          end

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
