# frozen_string_literal: true

module SpecForge
  module Documentation
    class Document
      #
      # Represents a response body structure
      #
      # Contains the type and content structure of a response body.
      #
      # @example Object response body
      #   ResponseBody.new(
      #     type: "object",
      #     content: {user: {type: "object", content: {id: {type: "integer"}}}}
      #   )
      #
      # @example Array response body
      #   ResponseBody.new(
      #     type: "array",
      #     content: [{type: "string"}]
      #   )
      #
      class ResponseBody < Data.define(:type, :content)
      end
    end
  end
end
