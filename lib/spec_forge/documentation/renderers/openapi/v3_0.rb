# frozen_string_literal: true

module SpecForge
  module Documentation
    module Renderers
      module OpenAPI
        class V3_0 < Base # standard:disable Naming/ClassAndModuleCamelCase
          CURRENT_VERSION = "3.0.4"

          def render
            {
              openapi: export_openapi_version,
              info: export_info,
              paths: export_paths
            }.merge_compact(
              servers: export_servers,
              components: export_components,
              security: export_security,
              tags: export_tags,
              externalDocs: export_external_docs
            )
          end

          protected

          # https://spec.openapis.org/oas/v3.0.4.html#openapi-object
          def export_openapi_version
            CURRENT_VERSION
          end

          # https://spec.openapis.org/oas/v3.0.4.html#info-object
          def export_info
            config[:info]
          end

          # https://spec.openapis.org/oas/v3.0.4.html#server-object
          def export_servers
            config[:servers]
          end

          # https://spec.openapis.org/oas/v3.0.4.html#paths-object
          def export_paths
            path_documentation = parse_user_defined_paths
            paths = input.endpoints.deep_dup

            paths.each do |path, operations|
              operations.transform_values!(with_key: true) do |document, operation|
                documentation = path_documentation.dig(path, operation) || {}

                Documentation::OpenAPI::V3_0::Operation.new(document, documentation:).to_h
              end
            end
          end

          # https://spec.openapis.org/oas/v3.0.4.html#components-object
          def export_components
            nil
          end

          # https://spec.openapis.org/oas/v3.0.4.html#security-requirement-object
          def export_security
            config[:security]
          end

          # https://spec.openapis.org/oas/v3.0.4.html#tag-object
          def export_tags
            tags = config[:tags] || {}

            tags.map do |name, description_or_hash|
              tag = {name: name.to_s}

              case description_or_hash
              when String
                tag[:description] = description_or_hash
              when Hash
                description_or_hash.rename_key_unordered!(:external_docs, :externalDocs)
                tag.merge!(description_or_hash)
              end

              tag
            end
          end

          # https://spec.openapis.org/oas/v3.0.4.html#external-documentation-object
          def export_external_docs
            nil
          end
        end
      end
    end
  end
end
