# frozen_string_literal: true

module SpecForge
  module Documentation
    class Builder
      # TODO: Docs
      class Extractor
        # TODO: Docs
        def initialize(context)
          @context = context
          @step = context.step
          @variables = context.variables
        end

        # TODO: Docs

        def extract_endpoint
          request = @variables[:request]
          response = @variables[:response]
          headers = request[:headers]

          {
            # Request data
            base_url: request[:base_url],
            url: request[:url],
            http_verb: request[:http_verb],
            content_type: headers["content-type"],
            request_body: request[:body],
            request_headers: headers.except("content-type"),
            request_query: request[:query],

            # Response data
            response_status: response[:status],
            response_body: response[:body],
            response_headers: response[:headers]
          }
        end
      end
    end
  end
end
