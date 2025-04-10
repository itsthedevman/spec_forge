# frozen_string_literal: true

module SpecForge
  module Documentation
    module Renderers
      module OpenAPI
        class V3_0 < Base # standard:disable Naming/ClassAndModuleCamelCase
          CURRENT_VERSION = "3.0.4"

          def config
            @config ||= Documentation.config[:openapi]
          end

          # https://spec.openapis.org/oas/v3.0.4.html#openapi-object
          def render
            output[:openapi] = config[:version].presence || CURRENT_VERSION
            output[:info] = export_info
            output[:servers] = export_servers
            output[:tags] = export_tags
            output[:security] = export_security
            output[:paths] = {}
            output[:components] = {}
            output
          end

          protected

          # https://spec.openapis.org/oas/v3.0.4.html#info-object
          def export_info
            input.info.to_h
          end

          # https://spec.openapis.org/oas/v3.0.4.html#server-object
          def export_servers
            config[:servers] || []
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
                description_or_hash[:externalDocs] = description_or_hash.delete(:external_docs)
                tag.merge!(description_or_hash)
              end

              tag
            end
          end

          # https://spec.openapis.org/oas/v3.0.4.html#security-requirement-object
          def export_security
            config[:security] || []
          end
        end
      end
    end
  end
end
