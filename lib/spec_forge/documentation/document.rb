# frozen_string_literal: true

module SpecForge
  module Documentation
    #
    # Represents the structured API documentation
    #
    # This class is the central data structure for API documentation,
    # containing all endpoints organized by path and HTTP method.
    # It serves as the bridge between extracted test data and renderers.
    #
    # @example Creating a document
    #   document = Document.new(
    #     endpoints: {
    #       "/users" => {
    #         "get" => {id: "list_users", description: "List all users"...},
    #         "post" => {id: "create_user", description: "Create a user"...}
    #       }
    #     }
    #   )
    #
    class Document < Data.define(:endpoints)
      #
      # Creates a new document with normalized endpoints
      #
      # @param endpoints [Hash] A hash mapping paths to operations by HTTP method
      #
      # @return [Document] A new document instance
      #
      def initialize(endpoints: {})
        endpoints = endpoints.transform_values do |operations|
          operations.transform_keys(&:downcase)
            .transform_values! { |op| Operation.new(**op) }
        end

        endpoints.deep_symbolize_keys!

        super
      end
    end
  end
end

require_relative "document/operation"
require_relative "document/parameter"
require_relative "document/request_body"
require_relative "document/response"
require_relative "document/response_body"
