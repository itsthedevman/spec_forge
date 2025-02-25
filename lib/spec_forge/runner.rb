# frozen_string_literal: true

module SpecForge
  class Runner
    class << self
      #
      # Runs any specs
      #
      def run
        # Allows me to modify the error backtrace reporting within rspec
        RSpec.configuration.instance_variable_set(:@backtrace_formatter, BacktraceFormatter)

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
            # Define the example group
            describe(expectation.name) do
              # Set up the class metadata for error reporting
              runner_forge.set_group_metadata(self, spec_forge, expectation)

              constraints = expectation.constraints

              let!(:expected_status) { constraints.status.resolve }
              let!(:expected_json) { constraints.json.resolve }
              let!(:expected_json_class) { expected_json&.expected.class }

              before do
                # Ensure all variables are called and resolved, in case they are not referenced
                expectation.variables.resolve

                # Set up the example metadata for error reporting
                runner_forge.set_example_metadata(spec_forge, expectation)
              end

              subject(:response) { expectation.http_client.call }

              it do
                if spec_forge.debug? || expectation.debug?
                  runner_forge.handle_debug(expectation, self)
                end

                # Status check
                expect(response.status).to eq(expected_status)

                # JSON check
                if expected_json
                  expect(response.body).to be_kind_of(expected_json_class)
                  expect(response.body).to expected_json
                end
              end
            end
          end
        end
      end

      # @private
      def handle_debug(...)
        DebugProxy.new(...).call
      end

      # @private
      def set_group_metadata(context, spec, expectation)
        metadata = {
          file_path: spec.file_path,
          absolute_file_path: spec.file_path,
          line_number: spec.line_number,
          location: spec.file_path,
          rerun_file_path: "#{spec.file_name}:#{spec.name}:\"#{expectation.name}\""
        }

        context.metadata.merge!(metadata)
      end

      # @private
      def set_example_metadata(spec, expectation)
        # This is needed when an error raises in an example
        metadata = {location: "#{spec.file_path}:#{spec.line_number}"}

        RSpec.current_example.metadata.merge!(metadata)
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
