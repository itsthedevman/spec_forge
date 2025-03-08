# frozen_string_literal: true

module SpecForge
  class Runner
    class DebugProxy
      def self.default
        -> { puts inspect }
      end

      attr_reader :rspec_example, :spec, :expectation

      delegate_missing_to :@rspec_example

      def initialize(rspec_example, spec, expectation)
        @callback = SpecForge.configuration.on_debug

        @rspec_example = rspec_example
        @spec = spec
        @expectation = expectation
      end

      def call
        puts <<~STRING

          Debug triggered for: #{expectation.name}

          Available debugging contexts:
          - spec: Current spec details
          - expectation: Current expectation being tested
          - variables: Variables defined for this test
          - global: Global context shared across tests

          Request & Response:
          - request: HTTP request details (method, url, headers, body)
          - response: HTTP response with headers, status and body

          Expectations:
          - expected_status: Expected HTTP status code
          - expected_json: Expected response body structure
          - expected_json_class: Expected response body class type

          Helper objects:
          - http_client: The HTTP client used for the request
          - request_data: Raw request configuration data
          - rspec_example: Current RSpec example context

          💡 Pro tips:
            - Type 'self' or 'inspect' for a pretty-printed JSON overview
            - Use 'to_h' for the hash representation
            - Access the shared context with 'SpecForge.context'
        STRING

        instance_exec(&@callback)
      end

      ##########################################################################

      def global
        @global ||= begin
          hash = SpecForge.context.global.to_h
          hash[:variables].transform_values!(&:resolve)
          hash
        end
      end

      def variables
        @variables ||= SpecForge.context.variables.to_h.transform_values(&:resolve)
      end

      ##########################################################################

      def to_h
        spec_hash = spec.to_h
        spec_hash[:expectations].map! do |exp|
          exp[:expect][:json] = matchers_to_description(exp[:expect][:json])
          exp
        end

        expectation_hash = @expectation.to_h
        expectation_hash[:expect][:json] = matchers_to_description(expectation_hash[:expect][:json])

        {
          spec: spec_hash,
          expectation: expectation_hash,
          request: request.to_h,
          global:,
          variables:,
          response: {
            headers: response.headers,
            status: response.status,
            body: response.body
          }
        }
      end

      def inspect
        JSON.pretty_generate(to_h)
      end

      private

      def matchers_to_description(value)
        return value unless value.is_a?(RSpec::Matchers::BuiltIn::BaseMatcher)

        value.description
      end
    end
  end
end
