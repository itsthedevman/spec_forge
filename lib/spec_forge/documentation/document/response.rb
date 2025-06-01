# frozen_string_literal: true

module SpecForge
  module Documentation
    class Document
      #
      # Represents a possible response from an API operation
      #
      # Contains the status code, headers, and body content
      # with content type information.
      #
      # @example Success response
      #   Response.new(
      #     content_type: "application/json",
      #     status: 200,
      #     headers: {"Cache-Control" => {type: "string"}},
      #     body: {type: "object", content: {id: {type: "integer"}}}
      #   )
      #
      class Response < Data.define(:content_type, :status, :headers, :body)
        #
        # Creates a new response with a normalized body
        #
        # @param content_type [String] The content type (e.g., "application/json")
        # @param status [Integer] The HTTP status code
        # @param headers [Hash] Response headers with their types
        # @param body [Hash] Response body description
        #
        # @return [Response] A new response instance
        #
        def initialize(content_type:, status:, headers:, body:)
          body = ResponseBody.new(**body) if body.present?

          super
        end
      end
    end
  end
end
