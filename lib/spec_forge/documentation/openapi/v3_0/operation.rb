# frozen_string_literal: true

module SpecForge
  module Documentation
    module OpenAPI
      module V3_0 # standard:disable Naming/ClassAndModuleCamelCase
        class Operation < OpenAPI::Base
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
            id = documentation[:operation_id] || document.id.to_camelcase(:lower)
            id.presence
          end

          alias_method :operationId, :id

          def summary
            summary = documentation[:summary] || document.id.humanize
            summary.presence
          end

          def description
            description = documentation[:description] || document.description
            description.presence
          end

          def security
            documentation[:security]
          end

          def tags
            tags = documentation[:tags] || {}
            tags = tags.map { |name, data| Tag.parse(name, data).to_h }

            tags.presence
          end

          def external_docs
            documentation[:external_docs].presence
          end

          alias_method :externalDocs, :external_docs

          def deprecated
            documentation[:deprecated] ? true : nil
          end

          def servers
            documentation[:servers]
          end

          def callbacks
            documentation[:callbacks]
          end

          def parameters
            document.parameters.values.map do |parameter|
              schema = Schema.new(type: parameter.type).to_h

              {
                schema:,
                name: parameter.name,
                in: parameter.location,
                required: parameter.location == "path" || false
              }
            end
          end

          def request_body
            requests = document.requests
            return if requests.blank?

            request_docs = documentation[:request_body] || {}
            content_docs = request_docs[:content] || {}

            requests = requests.group_by(&:content_type)

            content =
              requests.transform_values(with_key: true) do |grouped_requests, content_type|
                docs = content_docs[content_type] || {}

                media_type_from_requests(grouped_requests, docs)
              end

            {
              required: request_docs[:required] == true,
              description: request_docs[:description],
              content:
            }
          end

          alias_method :requestBody, :request_body

          def responses
            response_docs = documentation[:responses] || {}

            document.responses
              .group_by(&:status)
              .stringify_keys
              .transform_values!(with_key: true) do |responses, status_code|
                docs = response_docs[status_code] || {}

                response = responses.first
                Response.new(response, documentation: docs).to_h
              end
          end

          private

          def media_type_from_requests(requests, docs)
            request = requests.first
            schema = Schema.new(type: request.type, content: request.content).to_h

            examples =
              requests.to_h do |request|
                example_name = request.name.to_camelcase(:lower)
                example = Example.new(summary: request.name, value: request.content).to_h

                [example_name, example]
              end

            MediaType.new(schema:, examples:, **docs).to_h
          end
        end
      end
    end
  end
end
