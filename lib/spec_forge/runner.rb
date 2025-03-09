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
        runner = self

        # This is just like writing a normal RSpec test
        RSpec.describe(forge.name) do
          # Specs
          forge.specs.each do |spec|
            # Describe the spec
            describe(spec.name) do
              # Request data is for the spec and contains the base and overlays
              let!(:request_data) { forge.request[spec.id] }

              # The HTTP client for the spec
              let!(:http_client) { HTTP::Client.new(**request_data[:base]) }

              # This only happens once for the entire file
              before :context do
                # Update the various contexts (global, variables, etc.) for the current spec
                runner.prepare_context(forge, spec)
              end

              # Expectations
              spec.expectations.each do |expectation|
                # Setup the variables and metadata
                before do
                  runner.prepare_variables(expectation)
                  runner.set_example_metadata(spec, expectation)
                end

                after do
                  # store if set
                end

                # Onto the actual expectation itself
                describe(expectation.name) do
                  # More metadata definition
                  runner.set_group_metadata(self, spec, expectation)

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

                  # The test itself. Went with no name so RSpec would handle it
                  it do
                    if spec.debug? || expectation.debug?
                      runner.handle_debug(self, spec, expectation)
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

      #
      # Handles debugging an example during execution
      # Provides access to test state for debugging
      #
      # @param example [RSpec::Core::Example] The current example
      # @param spec [SpecForge::Spec] The spec being tested
      # @param expectation [SpecForge::Spec::Expectation] The expectation being evaluated
      #
      # @private
      #
      def handle_debug(example, spec, expectation)
        DebugProxy.new(example, spec, expectation).call
      end

      #
      # Prepares the various contexts for the provided forge
      # Sets up global, metadata, and variable contexts
      #
      # @param forge [SpecForge::Forge] The forge to prepare context for
      # @param spec [SpecForge::Spec] The spec to prepare
      #
      # @private
      #
      def prepare_context(forge, spec)
        SpecForge.context.global.update(**forge.global)
        SpecForge.context.metadata.update(**forge.metadata)
        SpecForge.context.variables.update(**forge.variables_for_spec(spec))
      end

      #
      # Overlays expectation level variables over spec level variables
      # Sets up the variable context for an expectation
      #
      # @param expectation [SpecForge::Spec::Expectation] The expectation to prepare
      #
      # @private
      #
      def prepare_variables(expectation)
        # Load the overlay
        SpecForge.context.variables.use_overlay(expectation.id)

        # Resolve everything
        SpecForge.context.global.variables.resolve
        SpecForge.context.variables.resolve
      end

      #
      # Updates the example group metadata for error reporting
      # Used by RSpec for formatting error messages
      #
      # @param example_group [RSpec::Core::ExampleGroup] The example group
      # @param spec [SpecForge::Spec] The spec being tested
      # @param expectation [SpecForge::Spec::Expectation] The expectation being evaluated
      #
      # @private
      #
      def set_group_metadata(example_group, spec, expectation)
        metadata = {
          file_path: spec.file_path,
          absolute_file_path: spec.file_path,
          line_number: spec.line_number,
          location: spec.file_path,
          rerun_file_path: "#{spec.file_name}:#{spec.name}:\"#{expectation.name}\""
        }

        example_group.metadata.merge!(metadata)
      end

      #
      # Updates the current example's metadata for error reporting
      # Used by RSpec for formatting error messages
      #
      # @param spec [SpecForge::Spec] The spec being tested
      # @param expectation [SpecForge::Spec::Expectation] The expectation being evaluated
      #
      # @private
      #
      def set_example_metadata(spec, expectation)
        # This is needed when an error raises in an example
        metadata = {location: "#{spec.file_path}:#{spec.line_number}"}

        RSpec.current_example.metadata.merge!(metadata)
      end

      private

      def prepare_for_run
        # Allows modifying the error backtrace reporting within rspec
        RSpec.configuration.instance_variable_set(:@backtrace_formatter, BacktraceFormatter)
      end
    end
  end
end

require_relative "runner/debug_proxy"
