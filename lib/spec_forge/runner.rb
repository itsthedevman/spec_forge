# frozen_string_literal: true

module SpecForge
  class Runner
    class << self
      #
      # Runs any specs
      #
      def run
        RSpec::Core::Runner.disable_autorun!
        RSpec::Core::Runner.run([], $stderr, $stdout)
      end

      #
      # Defines a spec with RSpec
      #
      # @param spec_forge [Spec] The spec to define
      #
      def define_spec(spec_forge)
        runner_forge = self

        RSpec.describe(spec_forge.name) do
          spec_forge.expectations.each do |expectation|
            describe(expectation.name) do
              # Define the example group
              request = expectation.http_client.request

              context "#{request.http_method} #{request.url}" do
                constraints = expectation.constraints

                let!(:expected_status) { constraints.status.resolve }
                let!(:expected_json) { constraints.json.resolve.deep_stringify_keys }

                subject(:response) { expectation.http_client.call }

                it do
                  runner_forge.handle_debug(expectation, self) if expectation.debug?

                  # Status check
                  expect(response.status).to eq(expected_status)

                  # JSON check
                  if constraints.json.size > 0
                    expect(response.body).to be_kind_of(Hash)
                    expect(response.body).to include(expected_json)
                  end
                end
              end
            end
          end
        end
      end

      def handle_debug(...)
        DebugProxy.new(...).call
      end
    end

    ################################################################################################

    class DebugProxy
      def self.default
        -> { puts inspect }
      end

      attr_reader :expectation, :variables, :expected_status, :expected_json, :request, :response

      def initialize(expectation, spec_context)
        @callback = SpecForge.configuration.on_debug

        @expected_status = spec_context.expected_status
        @expected_json = spec_context.expected_json

        @request = expectation.http_client.request
        @response = spec_context.response

        @variables = expectation.variables
        @expectation = expectation
      end

      def call
        puts <<~STRING

          Debug triggered for: #{expectation.name}

          Available methods:
          - expectation: Full expectation context
          - variables: Current variable definitions
          - expected_status: Expected HTTP status code (#{expected_status})
          - expected_json: Expected response body (after resolution)
          - request: HTTP request details (method, url, headers, body)
          - response: HTTP response (if after request)

          Tip: Type 'self' for a JSON overview of the current state
               Individual methods return full object details for advanced debugging
        STRING

        instance_exec(&@callback)
      end

      def inspect
        JSON.pretty_generate(expectation.to_h)
      end
    end
  end
end
