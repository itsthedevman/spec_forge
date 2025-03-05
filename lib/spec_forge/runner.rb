# frozen_string_literal: true

module SpecForge
  class Runner
    class << self
      def context
        @context ||= Context::Manager.new
      end

      def define(forges)
        forges.each do |forge|
          define_forge(forge)
        end
      end

      def run
        prepare_for_run
        RSpec::Core::Runner.invoke
      end

      def define_forge(forge)
        runner = self

        RSpec.describe(forge.name) do
          # Specs
          forge.specs.each do |spec|
            before :context do
              # Update the various contexts (global, variables, etc.) for the current spec
              runner.prepare_context(forge, spec)
            end

            # Spec
            describe(spec.name) do
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
                  let(:request) { HTTP::Request.new }

                  # subject(:response) { expectation.http_client.call }

                  it do
                    if spec.debug? || expectation.debug?
                      runner.handle_debug(expectation, self)
                    end

                    # # Status check
                    # expect(response.status).to eq(expected_status)

                    # # JSON check
                    # if expected_json
                    #   expect(response.body).to be_kind_of(expected_json_class)
                    #   expect(response.body).to expected_json
                    # end
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
      # @param expectation [SpecForge::Spec::Expectation]
      # @param spec_context [RSpec::Core::Example]
      #
      # @private
      #
      def handle_debug(expectation, spec_context)
        DebugProxy.new(expectation, spec_context).call
      end

      #
      # Prepares the various contexts for the provided forge
      #
      # @param forge [SpecForge::Forge]
      #
      # @private
      #
      def prepare_context(forge, spec)
        context.global.update(forge.global)
        context.metadata.update(forge.metadata)
        context.variables.update(**forge.variables_for_spec(spec))
      end

      #
      # Overlays any expectation level variables over the spec level variables
      #
      # @param expectation [SpecForge::Spec::Expectation]
      #
      # @private
      #
      def prepare_variables(expectation)
        context.variables.use_overlay(expectation.id)
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
