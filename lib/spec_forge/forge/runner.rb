# frozen_string_literal: true

module SpecForge
  class Forge
    class Runner
      attr_reader :output_io, :error_io

      def initialize(cli_args = [])
        options = RSpec::Core::ConfigurationOptions.new(cli_args)

        @configuration = RSpec.configuration.deep_dup
        reset_configuration # Must be done before runner is configured

        @world = RSpec::Core::World.new
        @runner = RSpec::Core::Runner.new(options, @configuration, @world)

        @output_io = ArrayIO.new
        @error_io = StringIO.new
        @runner.configure(@error_io, @output_io)
      end

      def build(forge, step, expectation)
        @world.example_groups << create_example_group(forge, step, expectation)
      end

      def run
        @runner.run_specs(@world.ordered_example_groups)

        entry = @output_io.entries.last.to_h
        entry[:examples].reject { |ex| ex[:status] == "passed" }
      ensure
        @world.reset
        reset_configuration
      end

      private

      def reset_configuration
        # Resetting the configuration also means resetting the Formatters/Reporters.
        @configuration.reset
        @configuration.add_formatter(RSpec::Core::Formatters::JsonFormatter)
      end

      def create_example_group(forge, step, expectation)
        RSpec::Core::ExampleGroup.describe(step.source.to_s) do
          let(:display) { forge.display }
          let(:response) { forge.variables[:response] }

          let(:headers) { response.headers }
          let(:body) { response.body.is_a?(Hash) ? response.body.deep_stringify_keys : response.body }

          ############################################################
          # Status check
          if (status_matcher = expectation.status_matcher)
            it "Status" do
              expect(response.status).to status_matcher

              display.success("Status", indent: 1)
            end
          end

          ############################################################
          # Headers check
          if (headers_matcher = expectation.headers_matcher)
            it "Headers" do
              HeaderValidator.new(headers, headers_matcher).validate!

              display.success("Headers", indent: 1)
            end
          end

          ############################################################
          # JSON checks
          if (json_size_matcher = expectation.json_size_matcher)
            it "JSON size" do
              expect(body.size).to json_size_matcher

              display.success("JSON size", indent: 1)
            end
          end

          if (schema_structure = expectation.json_schema)
            it "JSON schema" do
              SchemaValidator.new(body, schema_structure).validate!

              display.success("JSON schema", indent: 1)
            end
          end

          if (content_matcher = expectation.json_content_matcher)
            it "JSON content" do
              ContentValidator.new(body, content_matcher).validate!

              display.success("JSON content", indent: 1)
            end
          end
        end
      end
    end
  end
end
