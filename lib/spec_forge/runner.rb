# frozen_string_literal: true

module SpecForge
  class Runner
    class << self
      def define(forges)
        forges.each do |forge|
          define_forge(forge)
        end
      end

      def run
        prepare_for_run

        ARGV.clear
        RSpec::Core::Runner.invoke
      end

      def define_forge(forge)
        runner = self

        RSpec.describe(forge.name) do
          # Specs
          forge.specs.each do |spec|
            # Spec
            describe(spec.name) do
              let!(:request_data) { forge.request[spec.id] }
              let!(:http_client) { HTTP::Client.new(**request_data[:base]) }

              before :context do
                # Update the various contexts (global, variables, etc.) for the current spec
                runner.prepare_context(forge, spec)
              end

              # Expectations
              spec.expectations.each do |expectation|
                before do
                  runner.prepare_variables(expectation)
                  runner.set_example_metadata(spec, expectation)
                end

                after do
                  # store if set
                end

                # Expectation
                describe(expectation.name) do
                  runner.set_group_metadata(self, spec, expectation)

                  # Define the constraints
                  let(:expected_status) { expectation.constraints.status.resolve }
                  let(:expected_json) { expectation.constraints.json.resolve }
                  let(:expected_json_class) { expected_json&.expected.class }

                  let(:request) do
                    request = request_data[:base]

                    if (overlay = request_data[:overlay][expectation.id])
                      request = request.merge(overlay)
                    end

                    HTTP::Request.new(**request)
                  end

                  subject(:response) { http_client.call(request) }

                  it do
                    if spec.debug? || expectation.debug?
                      runner.handle_debug(self, expectation)
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
      # Handles debugging an example
      #
      # @param spec_context [RSpec::Core::Example]
      # @param expectation [SpecForge::Spec::Expectation]
      #
      # @private
      #
      def handle_debug(spec_context, expectation)
        DebugProxy.new(spec_context, expectation).call
      end

      #
      # Prepares the various contexts for the provided forge
      #
      # @param forge [SpecForge::Forge]
      #
      # @private
      #
      def prepare_context(forge, spec)
        SpecForge.context.global.update(**forge.global)
        SpecForge.context.metadata.update(**forge.metadata)
        SpecForge.context.variables.update(**forge.variables_for_spec(spec))
      end

      #
      # Overlays any expectation level variables over the spec level variables
      #
      # @param expectation [SpecForge::Spec::Expectation]
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
      # Updates the example group metadata
      # Used for error reporting by RSpec
      #
      # @param context [RSpec::Core::ExampleGroup]
      # @param spec [SpecForge::Spec]
      # @param expectation [SpecForge::Spec::Expectation]
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
      # Updates the current example's metadata
      # Used for error reporting by RSpec
      #
      # @param spec [SpecForge::Spec]
      # @param expectation [SpecForge::Spec::Expectation]
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
