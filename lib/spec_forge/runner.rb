# frozen_string_literal: true

module SpecForge
  #
  # Handles the execution of specs through RSpec
  # Converts SpecForge specs into RSpec examples and runs them
  #
  class Runner
    class << self
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

              # Expectations
              spec.expectations.each do |expectation|
                # Callbacks for the expectation
                before { Callbacks.before_expectation(forge, spec, expectation) }
                after { Callbacks.after_expectation(forge, spec, expectation) }

                # Onto the actual expectation itself
                describe(expectation.name) do
                  # Set metadata for the example group for error reporting
                  Metadata.set_for_group(spec, expectation, self)

                  # Lazily load the constraints
                  let(:expected_status) { expectation.constraints.status.resolve }
                  let(:expected_json) { expectation.constraints.json.resolve }
                  let(:expected_json_class) { expected_json&.expected.class }

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

                  # The test itself. Went with no name so RSpec will pick the failure as the message
                  it do
                    if spec.debug? || expectation.debug?
                      Callbacks.on_debug(forge, spec, expectation, self)
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
        end
      end

      private

      def prepare_for_run
        # Allows modifying the error backtrace reporting within rspec
        RSpec.configuration.instance_variable_set(:@backtrace_formatter, BacktraceFormatter)
      end
    end
  end
end

require_relative "runner/callbacks"
require_relative "runner/debug_proxy"
require_relative "runner/metadata"
