# frozen_string_literal: true

module SpecForge
  module Documentation
    module OpenAPI
      module V3_0 # standard:disable Naming/ClassAndModuleCamelCase
        class Operation
          def initialize(document, documentation: {})
            @document = document
            @documentation = documentation
          end

          def to_h
            {
              # Required
              responses:
            }.merge_compact(
              # All optional
              tags:,
              summary:,
              description:,
              externalDocs:,
              operationId:,
              parameters:,
              requestBody:,
              callbacks:,
              deprecated:,
              security:,
              servers:
            )
          end

          def id
            @documentation[:operation_id] || @document.id.to_camelcase(:lower)
          end

          alias_method :operationId, :id

          def summary
            @documentation[:summary] || @document.id.humanize
          end

          def description
            @documentation[:description] || @document.description
          end

          def security
            [{}]
          end

          def tags
            nil
          end

          def external_docs
            nil
          end

          alias_method :externalDocs, :external_docs

          def deprecated
            nil
          end

          def servers
            nil
          end

          def callbacks
            nil
          end

          def parameters
            @document.parameters.values.map do |parameter|
              schema = OpenAPI::V3_0::Schema.create_hash(type: params.delete(:type))

              {
                name: parameter.name,
                in: parameter.location,
                schema:,
                required: parameter.location == "path" || false
              }
            end
          end

          def request_body
          end

          alias_method :requestBody, :request_body

          private

          def export_request_body(requests, documentation)
            # Requests may have multiple entries for the same content_type
            content = requests.group_by(&:content_type)
            content_docs = documentation[:content]

            # We'll convert those to examples
            content.transform_values!(with_key: true) do |grouped_requests, content_type|
              docs = content_docs[content_type]
              request = grouped_requests.first

              content = request.content

              # Create a schema from the types
              schema = type_to_schema(request.type)
              schema.merge!(content_to_schema(content))

              {
                schema:,
                examples: grouped_requests.to_h do |request|
                  [
                    request.name.to_camelcase(:lower),
                    {
                      summary: request.name,
                      value: content
                    }
                  ]
                end
              }.merge(docs)
            end

            {
              required: documentation[:required] == true,
              description: documentation[:description],
              content:
            }
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
