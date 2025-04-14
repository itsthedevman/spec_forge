# frozen_string_literal: true

module SpecForge
  module Documentation
    class Document
      #
      # Represents a request body example for an API operation
      #
      # Contains the content type, data structure, and example content
      # for a request body.
      #
      # @example JSON request body
      #   RequestBody.new(
      #     name: "Create User",
      #     content_type: "application/json",
      #     type: "object",
      #     content: {name: "Example User", email: "user@example.com"}
      #   )
      #
      class RequestBody < Data.define(:name, :content_type, :type, :content)
      end
    end
  end
end
