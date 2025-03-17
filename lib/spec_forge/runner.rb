# frozen_string_literal: true

module SpecForge
  #
  # Handles the execution of specs through RSpec
  # Converts SpecForge specs into RSpec examples and runs them
  #
  class Runner
    class << self
      #
      # Stores context information about the currently executing example
      #
      # This hash contains references to objects that define the current test context,
      # including the forge, spec, expectation, and example group. It's used to bridge
      # the gap between RSpec's regular flow and its notification system.
      #
      # @return [Hash] A hash containing :forge, :spec, :expectation, and :example_group keys
      #
      # @example Setting the current context
      #   Runner.current_example_context = {
      #     forge: forge,
      #     spec: spec,
      #     expectation: expectation,
      #     example_group: example_group
      #   }
      #
      # @api private
      #
      attr_accessor :current_example_context

      #
      # Defines RSpec examples for a collection of forges
      # Creates the test structure that will be executed
      #
      # @param forges [Array<Forge>] The forges to define as RSpec examples
      #
      def define(forges)
        forges.each do |forge|
          define_forge(forge)
        end
      end

      #
      # Runs the defined RSpec examples
      # Executes the tests after they've been defined
      #
      def run
        prepare_for_run

        ARGV.clear
        RSpec::Core::Runner.invoke
      end

      #
      # Defines RSpec examples for a specific forge
      # Creates the test structure for a single forge file
      #
      # @param forge [Forge] The forge to define
      #
      def define_forge(forge)
        # This is just like writing a normal RSpec test, except with loops ;)
        RSpec.describe(forge.name) do
          # Callback for the file
          before(:context) { Callbacks.before_file(forge) }
          after(:context) { Callbacks.after_file(forge) }

          # Specs
          forge.specs.each do |spec|
            # Describe the spec
            describe(spec.name) do
              # Request data is for the spec and contains the base and overlays
              let!(:request_data) { forge.request[spec.id] }

              # The HTTP client for the spec
              let!(:http_client) { HTTP::Client.new(**request_data[:base]) }

              # Callback for the spec
              before(:context) { Callbacks.before_spec(forge, spec) }
              after(:context) { Callbacks.after_spec(forge, spec) }

              # Expectations
              spec.expectations.each do |expectation|
                # Onto the actual expectation itself
                describe(expectation.name) do
                  # Set metadata for the example group for error reporting
                  Metadata.set_for_group(spec, expectation, self)

                  # Lazily load the constraints
                  let(:constraints) { expectation.constraints.as_matchers }

                  let(:match_status) { constraints[:status] }
                  let(:match_json) { constraints[:json] }
                  let(:match_json_class) { be_kind_of(match_json.class) }

                  # The request for the test itself. Overlays the expectation's data if it exists
                  let(:request) do
                    request = request_data[:base]

                    if (overlay = request_data[:overlay][expectation.id])
                      request = request.merge(overlay)
                    end

                    HTTP::Request.new(**request)
                  end

                  # The Faraday response
                  subject(:response) { http_client.call(request) }

                  # Callback
                  before do
                    Callbacks.before_expectation(
                      forge, spec, expectation, self, RSpec.current_example
                    )

                    # The 'after_expectation' callback is handled by Listener due to RSpec not
                    # reporting the example's status until after the describe block has finished.
                    # That callback needs this information, let's go ahead and store it
                    Runner.current_example_context = {
                      forge:, spec:, expectation:, example_group: self
                    }
                  end

                  # The test itself. Went with no name so RSpec will pick the failure as the message
                  it do
                    if spec.debug? || expectation.debug?
                      Callbacks.on_debug(forge, spec, expectation, self)
                    end

                    # Status check
                    expect(response.status).to match_status

                    # JSON check
                    if match_json.present?
                      expect(response.body).to match_json_class

                      case match_json
                      when Hash
                        # Check per key for easier debugging
                        match_json.each do |key, matcher|
                          expect(response.body).to have_key(key)
                          expect(response.body[key]).to matcher
                        end
                      else
                        expect(response.body).to match_json
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end

      private

      def prepare_for_run
        # Allows modifying the error backtrace reporting within rspec
        RSpec.configuration.instance_variable_set(:@backtrace_formatter, BacktraceFormatter)

        # Listen for when a example passes or fails
        RSpec.configuration.reporter.register_listener(
          Listener.instance,
          :example_passed, :example_failed
        )

        @current_example_context = nil
      end
    end
  end
end

require_relative "runner/callbacks"
require_relative "runner/debug_proxy"
require_relative "runner/listener"
require_relative "runner/metadata"
