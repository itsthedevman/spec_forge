# frozen_string_literal: true

module SpecForge
  module Documentation
    class Builder
      class Extractor
        def initialize(context)
          @spec = context.spec
          @variables = context.variables
        end

        def extract_endpoints
          request = context.variables[:request]
          response = context.variables[:response]

          binding.pry
          # # Only pull the headers that the user explicitly checked for.
          # # This keeps the extra unrelated headers from being included
          # response_headers = context.expectation
          #   .constraints
          #   .headers
          #   .keys
          #   .map { |h| h.to_s.downcase }

          # response_headers = response_hash[:response_headers].slice(*response_headers)

          # {
          #   # Metadata
          #   spec_name: context.spec.name,
          #   expectation_name: context.expectation.name,

          #   # Request data
          #   base_url: request[:base_url],
          #   url: request[:url],
          #   http_verb: request[:http_verb],
          #   content_type: request[:content_type],
          #   request_body: request[:body],
          #   request_headers: request[:headers],
          #   request_query: request[:query],

          #   # Response data
          #   response_status: response[:status],
          #   response_body: response[:body],
          #   response_headers:
          # }
        end
      end
    end
  end
end
