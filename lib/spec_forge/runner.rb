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
        # Allows me to modify the error backtrace reporting within rspec
        RSpec.configuration.instance_variable_set(:@backtrace_formatter, BacktraceFormatter)
        RSpec::Core::Runner.invoke!
      end

      def define_forge(forge)
        runner = self

        RSpec.describe(forge.name) do
          forge.specs.each do |forge_spec|
            describe(forge_spec.name) do
              forge_spec.expectations do |expectation|
                # Set up the class metadata for error reporting
                runner.set_group_metadata(self, forge_spec, expectation)

                # constraints = expectation.constraints

                # let(:expected_status) { constraints.status.resolve }
                # let(:expected_json) { constraints.json.resolve }
                # let(:expected_json_class) { expected_json&.expected.class }

                before do
                  # Ensure all variables are called and resolved, in case they are not referenced

                  # Set up the example metadata for error reporting
                  runner.set_example_metadata(forge_spec, expectation)
                end

                # subject(:response) { expectation.http_client.call }

                it do
                  if forge_spec.debug? || expectation.debug?
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
  end
end

require_relative "runner/debug_proxy"
