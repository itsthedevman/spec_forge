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
            output[:paths] = export_paths
            output[:components] = {}
            output.deep_stringify_keys
          end

          protected

          # https://spec.openapis.org/oas/v3.0.4.html#info-object
          def export_info
            input.info.to_deep_h
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
                description_or_hash.rename_key_unordered!(:external_docs, :externalDocs)
                tag.merge!(description_or_hash)
              end

              tag
            end
          end

          # https://spec.openapis.org/oas/v3.0.4.html#security-requirement-object
          def export_security
            config[:security] || []
          end

          # https://spec.openapis.org/oas/v3.0.4.html#paths-object
          def export_paths
            paths = input.endpoints.deep_dup

            paths.each_value do |operations|
              operations.transform_values! do |document|
                parameters =
                  document.parameters.values.map do |parameter|
                    params = parameter.to_deep_h

                    params[:schema] = type_to_schema(params.delete(:type))
                    params[:required] = params[:in] == "path" || params[:required] || false

                    params.rename_key_unordered!(:location, :in)
                    params
                  end

                output = {
                  operationId: camelize(document.id),
                  description: document.description,
                  parameters:
                }

                if (requests = document.requests) && requests.present?
                  output[:requestBody] = export_request_body(requests)
                end

                if (responses = document.responses) && responses.present?
                  output[:responses] = export_responses(responses)
                end

                output
              end
            end
          end

          def export_request_body(requests)
            content = requests.group_by(&:content_type)

            content.transform_values! do |grouped_requests|
              request = grouped_requests.first

              content = request.content
              schema = type_to_schema(request.type, content: request.content)

              {
                schema:,
                examples: grouped_requests.to_h do |request|
                  [
                    camelize(request.name),
                    {
                      summary: request.name,
                      value: request.content
                    }
                  ]
                end
              }
            end

            {content:}
          end

          def export_responses(responses)
            responses.group_by(&:status)
              .stringify_keys
              .transform_values! do |responses|
                response = responses.first
                schema = type_to_schema(response.body.type, content: response.body.content)

                {
                  headers: response.headers,
                  content: {
                    response.content_type => {schema:}
                  }
                }
              end
          end
        end
      end
    end
  end
end
