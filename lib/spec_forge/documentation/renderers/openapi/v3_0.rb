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
              servers: export_servers,
              tags: export_tags,
              security: export_security,
              paths: export_paths,
              components: {}
            }
          end

          protected

          # https://spec.openapis.org/oas/v3.0.4.html#openapi-object
          def export_openapi_version
            config[:version].presence || CURRENT_VERSION
          end

          # https://spec.openapis.org/oas/v3.0.4.html#info-object
          def export_info
            config[:info]
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
            paths_documentation = parse_user_defined_paths
            paths = input.endpoints.deep_dup

            paths.each do |path, operations|
              operations.transform_values!(with_key: true) do |document, operation|
                documentation = paths_documentation.dig(path, operation) || {}

                parameters =
                  document.parameters.values.map do |parameter|
                    params = parameter.to_deep_h

                    params[:schema] = type_to_schema(params.delete(:type))
                    params[:required] = params[:location] == "path" || params[:required] || false

                    params.rename_key_unordered!(:location, :in)
                    params
                  end

                output = {
                  operationId: documentation[:operation_id] || camelize(document.id),
                  summary: documentation[:summary] || document.id.humanize,
                  description: documentation[:description] || document.description,
                  security: [{}],
                  parameters:
                }

                if (requests = document.requests) && requests.present?
                  output[:requestBody] = export_request_body(requests)
                end

                output[:responses] = {}
                # if (responses = document.responses) && responses.present?
                #   output[:responses] = export_responses(responses)
                # end

                output
              end
            end
          end

          def export_request_body(requests)
            content = requests.group_by(&:content_type)

            content.transform_values! do |grouped_requests|
              request = grouped_requests.first

              content = request.content

              schema = type_to_schema(request.type)
              schema.merge!(content_to_schema(request.content))

              {
                required: true,
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
                # I was trying to figure out how to get body content into the schema hash
                # in a way that makes it easy so I don't have to check for `items` or `properties`
                # But at the same time, content needs to have their types converted as well
                response = responses.first
                schema = type_to_schema(response.body.type)
                schema.merge!(content_to_schema(response.body.content))

                {
                  headers: response.headers,
                  description: "",
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
