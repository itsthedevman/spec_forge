# frozen_string_literal: true

module SpecForge
  class Runner
    #
    # Creates a debugging environment during test execution.
    # When a breakpoint is triggered, this provides an interface to inspect
    # the current test state including the request, response, variables, and expectations.
    #
    # By default, this outputs a JSON representation of the current testing context,
    # but it can be customized by configuring SpecForge.configuration.on_debug
    # to use any Ruby debugger (like pry or debug).
    #
    # @example Basic usage in a spec with `debug: true`
    #   # In your YAML test:
    #   get_users:
    #     debug: true
    #     path: /users
    #     expectations:
    #     - expect:
    #         status: 200
    #
    # @example Custom debug handler in forge_helper.rb
    #   SpecForge.configure do |config|
    #     config.on_debug { binding.pry } # Requires 'pry' gem
    #   end
    #
    class DebugProxy
      #
      # @return [Proc] The default debugging handler that outputs JSON state information
      #
      def self.default
        -> { puts inspect }
      end

      # @return [RSpec::Forge] The current Forge that is being tested
      attr_reader :forge

      # @return [SpecForge::Spec] The current Spec that is being tested
      attr_reader :spec

      # @return [SpecForge::Spec::Expectation] The current expectation that is being tested
      attr_reader :expectation

      # @return [RSpec::ExampleGroup] The current RSpec example group
      attr_reader :example_group

      # @return [RSpec::Example] The current RSpec example that is running
      attr_reader :example

      # @return [Integer] The expected HTTP status code
      attr_reader :expected_status

      # @return [Object] The expected response body structure
      attr_reader :expected_json

      delegate_missing_to :@example_group

      #
      # Creates a new DebugProxy instance
      #
      # @param forge [SpecForge::Forge] The forge being tested
      # @param spec [SpecForge::Spec] The spec being tested
      # @param expectation [SpecForge::Spec::Expectation] The expectation being tested
      # @param example_group [RSpec::Core::ExampleGroup] The current example group
      #
      # @return [SpecForge::Runner::DebugProxy]
      #
      def initialize(forge, spec, expectation, example_group)
        @callback = SpecForge.configuration.on_debug

        @forge = forge
        @spec = spec
        @expectation = expectation
        @example_group = example_group
        @example = RSpec.current_example

        constraints = expectation.constraints

        @expected_status = constraints.status.resolve
        @expected_json = constraints.json.resolve
      end

      #
      # Triggers the debugging environment
      #
      # Displays available debugging contexts and executes the configured debug callback.
      # The callback runs in the context of this proxy, giving it access to all helper methods.
      #
      # @return [void]
      #
      def call
        puts <<~STRING

          Debug triggered for:
          > #{example.metadata[:rerun_file_path]} on line #{expectation.line_number}

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

          Matchers:
          - match_status: Matcher used to test status
          - match_json: Matcher used to test response body

          Helper objects:
          - http_client: The HTTP client used for the request
          - request_data: Raw request configuration data
          - example_group: Current RSpec example context
          - example: Current RSpec example
          - forge: Current file being tested

          💡 Pro tips:
            - Type 'self' or 'inspect' for a pretty-printed JSON overview
            - Use 'to_h' for the hash representation
            - Access the shared context with 'SpecForge.context'
        STRING

        instance_exec(&@callback)
      end

      ##########################################################################

      #
      # Returns a hash representation of the global context
      #
      # @return [Hash] The global context with resolved variables
      #
      def global
        @global ||= begin
          hash = SpecForge.context.global.to_h
          hash[:variables].resolve
          hash
        end
      end

      #
      # Returns a hash representation of the variables in the current context
      #
      # Includes both spec-level and expectation-level variables combined
      # with values fully resolved.
      #
      # @return [Hash]
      #
      def variables
        @variables ||= SpecForge.context.variables.resolve
      end

      ##########################################################################

      #
      # Returns a hash representation of the test state
      #
      # Includes the spec, expectation, request, response, variables and global context.
      # RSpec matchers are converted to human-readable descriptions.
      #
      # @return [Hash]
      #
      def to_h
        spec_hash = spec.to_h.except(:expectations)

        expectation_hash = expectation.to_h
        expectation_hash[:expect][:json] = matchers_to_description(expectation_hash[:expect][:json])

        {
          response: {
            status: response.status,
            body: response.body,
            headers: response.headers
          },
          global:,
          variables:,
          request: request.to_h,
          expectation: expectation_hash,
          spec: spec_hash
        }
      end

      #
      # Returns a formatted JSON representation of the test state
      #
      # @return [String] Pretty-printed JSON of the test state
      #
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
