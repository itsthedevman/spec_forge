# frozen_string_literal: true

module SpecForge
  class Runner
    class DebugProxy
      def self.default
        -> { puts inspect }
      end

      attr_reader :expectation, :variables, :request

      delegate_missing_to :@spec_context

      def initialize(expectation, spec_context)
        @callback = SpecForge.configuration.on_debug
        @spec_context = spec_context

        @expectation = expectation
        @request = expectation.http_client.request
        @variables = expectation.variables
      end

      def call
        puts <<~STRING

          Debug triggered for: #{expectation.name}

          Available methods:
          - expectation: Full expectation context
          - variables: Current variable definitions
          - expected_status: Expected HTTP status code
          - expected_json: Expected response body
          - expected_json_class: Expected response body class
          - request: HTTP request details (method, url, headers, body)
          - response: HTTP response

          Tip: Type 'self' for a JSON overview of the current state
               Individual methods return full object details for advanced debugging
        STRING

        instance_exec(&@callback)
      end

      def inspect
        hash = expectation.to_h

        hash[:response] = {
          headers: response.headers,
          status: response.status,
          body: response.body
        }

        JSON.pretty_generate(hash)
      end
    end
  end
end
