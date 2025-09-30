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
            }.compact_merge(
              # All optional
              tags:,
              summary:,
              description:,
              operationId:,
              parameters:,
              requestBody:
            )
          end

          #
          # Returns the operation's unique identifier
          #
          # @return [String] The operation ID
          #
          def id
            # The object ID is added to make every ID unique
            document.id.to_camelcase(:lower) + object_id.to_s
          end

          alias_method :operationId, :id

          #
          # Returns a human-readable summary of the operation
          #
          # @return [String, nil] Brief operation summary
          #
          def summary
            document.id.humanize
          end

          #
          # Returns detailed description of the operation
          #
          # @return [String] Detailed operation description
          #
          def description
            document.description
          end

          #
          # Returns security requirements for the operation
          #
          # @return [Array] Array of security requirement objects
          #
          def security
            # User defined
            []
          end

          #
          # Returns tags for categorizing the operation
          #
          # @return [Array] Array of tag names
          #
          def tags
            # User defined
            []
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

            requests = requests.group_by(&:content_type)

            content =
              requests.transform_values do |grouped_requests|
                media_type_from_requests(grouped_requests)
              end

            {
              description: "",
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
            document.responses
              .group_by(&:status)
              .transform_values! do |responses|
                response = responses.first
                Response.new(response).to_h
              end
          end

          private

          def media_type_from_requests(requests)
            request = requests.first
            schema = Schema.new(type: request.type, content: request.content).to_h

            examples =
              requests.to_h do |request|
                example_name = request.name.to_camelcase(:lower)
                example = Example.new(summary: request.name, value: request.content).to_h

                [example_name, example]
              end

            MediaType.new(schema:, examples:).to_h
          end
        end
      end
    end
  end
end
