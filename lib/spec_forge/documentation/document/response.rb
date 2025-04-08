# frozen_string_literal: true

module SpecForge
  module Documentation
    class Document
      class Response < Data.define(:status, :headers, :body)
        def initialize(status:, headers:, body:)
          body = ResponseBody.new(**body) if body.present?

          super
        end
      end
    end
  end
end
