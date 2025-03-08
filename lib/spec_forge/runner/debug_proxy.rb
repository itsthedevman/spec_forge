# frozen_string_literal: true

module SpecForge
  class Runner
    #
    # Creates a debugging environment during test execution.
    # When a breakpoint is triggered, this provides an interface to inspect
    # the current test state including the request, response, variables, and expectations.
    #
    # By default, this outputs a JSON representation of the current testing context,
    # but it can be customized by configuring {SpecForge.configuration.on_debug}
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

      # @return [RSpec::Example] The current RSpec example that is running
      attr_reader :rspec_example

      # @return [SpecForge::Spec] The current Spec that is being tested
      attr_reader :spec

      # @return [SpecForge::Spec::Expectation] The current expectation that is being tested
      attr_reader :expectation

      delegate_missing_to :@rspec_example

      #
      # Creates a new DebugProxy instance
      #
      # @param rspec_example [RSpec::Example] The current RSpec example being executed
      # @param spec [SpecForge::Spec] The spec being tested
      # @param expectation [SpecForge::Spec::Expectation] The expectation being evaluated
      #
      # @return [SpecForge::Runner::DebugProxy]
      #
      def initialize(rspec_example, spec, expectation)
        @callback = SpecForge.configuration.on_debug

        @rspec_example = rspec_example
        @spec = spec
        @expectation = expectation
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

      #
      # Returns a hash representation of the global context
      #
      # @return [Hash] The global context with resolved variables
      #
      def global
        @global ||= begin
          hash = SpecForge.context.global.to_h
          hash[:variables].transform_values!(&:resolve)
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
        @variables ||= SpecForge.context.variables.to_h.transform_values(&:resolve)
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
