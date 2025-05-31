# frozen_string_literal: true

module SpecForge
  module Documentation
    module OpenAPI
      module V3_0 # standard:disable Naming/ClassAndModuleCamelCase
        #
        # Represents an OpenAPI 3.0 Operation object
        #
        # Handles the complete definition of API operations including parameters,
        # request bodies, responses, and security requirements for OpenAPI specs.
        #
        # @see https://spec.openapis.org/oas/v3.0.4.html#operation-object
        #
        class Operation < OpenAPI::Base
          #
          # Converts the operation to an OpenAPI-compliant hash
          #
          # Builds the complete operation object with all required and optional
          # fields properly formatted for OpenAPI specification.
          #
          # @return [Hash] OpenAPI-formatted operation object
          #
          def to_h
            {
              # Required
              responses:,
              security:
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
              servers:
            )
          end

          #
          # Returns the operation's unique identifier
          #
          # Generates a camelCase operation ID from the document ID, with object ID
          # appended for uniqueness. Falls back to documentation-provided ID.
          #
          # @return [String, nil] The operation ID
          #
          def id
            # The object ID is added to make every ID unique
            id = documentation[:operation_id] || document.id.to_camelcase(:lower) + object_id.to_s
            id.presence
          end

          alias_method :operationId, :id

          #
          # Returns a human-readable summary of the operation
          #
          # Uses documentation-provided summary or generates one from the operation ID.
          #
          # @return [String, nil] Brief operation summary
          #
          def summary
            summary = documentation[:summary] || document.id.humanize
            summary.presence
          end

          #
          # Returns detailed description of the operation
          #
          # Uses documentation-provided description or falls back to document description.
          #
          # @return [String, nil] Detailed operation description
          #
          def description
            description = documentation[:description] || document.description
            description.presence
          end

          #
          # Returns security requirements for the operation
          #
          # @return [Array] Array of security requirement objects
          #
          def security
            documentation[:security] || []
          end

          #
          # Returns tags for categorizing the operation
          #
          # @return [Array, nil] Array of tag names
          #
          def tags
            tags = documentation[:tags] || []
            tags.presence
          end

          #
          # Returns external documentation reference
          #
          # @return [Hash, nil] External documentation object
          #
          def external_docs
            documentation[:external_docs].presence
          end

          alias_method :externalDocs, :external_docs

          #
          # Returns whether the operation is deprecated
          #
          # @return [Boolean, nil] True if deprecated, nil if not specified
          #
          def deprecated
            documentation[:deprecated] ? true : nil
          end

          #
          # Returns server overrides for the operation
          #
          # @return [Array, nil] Array of server objects
          #
          def servers
            documentation[:servers]
          end

          #
          # Returns callback definitions for the operation
          #
          # @return [Hash, nil] Callback definitions
          #
          def callbacks
            documentation[:callbacks]
          end

          #
          # Returns parameter definitions for the operation
          #
          # Transforms document parameters into OpenAPI parameter objects
          # with proper schema types and location information.
          #
          # @return [Array] Array of parameter objects
          #
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

          #
          # Returns request body definition for the operation
          #
          # Groups requests by content type and creates proper OpenAPI
          # request body object with examples and schemas.
          #
          # @return [Hash, nil] Request body object
          #
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
              description: request_docs[:description] || "",
              content:
            }
          end

          alias_method :requestBody, :request_body

          #
          # Returns response definitions for the operation
          #
          # Groups responses by status code and transforms them into
          # OpenAPI response objects with proper formatting.
          #
          # @return [Hash] Hash mapping status codes to response objects
          #
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
