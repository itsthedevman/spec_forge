# frozen_string_literal: true

module SpecForge
  module Documentation
    class Document
      #
      # Represents an API operation (endpoint + HTTP method)
      #
      # An Operation contains all the information about a specific API endpoint
      # with a specific HTTP method, including parameters, request bodies,
      # and possible responses.
      #
      # @example Operation for creating a user
      #   operation = Operation.new(
      #     id: "create_user",
      #     description: "Creates a new user",
      #     parameters: {id: {name: "id", location: "path", type: "integer"}},
      #     requests: [{name: "example", content_type: "application/json", type: "object", content: {}}],
      #     responses: [{status: 201, content_type: "application/json", headers: {}, body: {}}]
      #   )
      #
      class Operation < Data.define(:id, :description, :parameters, :requests, :responses)
        #
        # Creates a new operation with normalized sub-components
        #
        # @param id [String] Unique identifier for the operation
        # @param description [String] Human-readable description
        # @param parameters [Hash] Parameters by name with their details
        # @param requests [Array<Hash>] Request body examples
        # @param responses [Array<Hash>] Possible responses
        #
        # @return [Operation] A new operation instance
        #
        def initialize(id:, description:, parameters:, requests:, responses:)
          parameters = parameters.each_pair.map do |name, value|
            [name, Parameter.new(name: name.to_s, **value)]
          end.to_h

          requests = requests.map { |r| RequestBody.new(**r) }
          responses = responses.map { |r| Response.new(**r) }

          super
        end
      end
    end
  end
end
