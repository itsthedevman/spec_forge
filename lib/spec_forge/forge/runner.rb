# frozen_string_literal: true

module SpecForge
  class Forge
    class Runner
      attr_reader :output_io, :error_io

      def initialize(cli_args = [])
        options = RSpec::Core::ConfigurationOptions.new(cli_args)

        @configuration = RSpec.configuration.deep_dup
        @configuration.reset

        @world = RSpec::Core::World.new
        @runner = RSpec::Core::Runner.new(options, @configuration, @world)

        @output_io = ArrayIO.new
        @error_io = StringIO.new
        @runner.configure(@error_io, @output_io)
      end

      def run(forge, step, expectation)
        configure_formatters(forge)

        @runner.run_specs([create_example_group(forge, step, expectation)])

        entry = @output_io.entries.last.to_h
        entry[:examples].reject { |ex| ex[:status] == "passed" }
      end

      private

      def configure_formatters(forge)
        # Resetting the configuration also means resetting the Formatters/Reporters.
        @configuration.reset
        @configuration.add_formatter(RSpec::Core::Formatters::JsonFormatter)

        # Make sure to load a formatter first and register to its reporter.
        # Otherwise RSpec will default the reporter.
        @configuration.formatter_loader.reporter.register_listener(
          Reporter.new(forge), :example_passed, :example_failed
        )
      end

      def create_example_group(forge, step, expectation)
        RSpec::Core::ExampleGroup.describe(step.source.to_s, :spec_forge) do
          let(:response) { forge.variables[:response] }

          let(:headers) { response[:headers] }
          let(:body) { response[:body].is_a?(Hash) ? response[:body].deep_symbolize_keys : response[:body] }

          ############################################################
          # Status check
          if (status_matcher = expectation.status_matcher)
            it "Status" do
              expect(response[:status]).to status_matcher
            end
          end

          ############################################################
          # Headers check
          if (headers_matcher = expectation.headers_matcher)
            it "Headers" do
              HeaderValidator.new(headers, headers_matcher).validate!
            end
          end

          ############################################################
          # JSON checks
          if (json_size_matcher = expectation.json_size_matcher)
            it "JSON size" do
              expect(body.size).to json_size_matcher
            end
          end

          if (schema_structure = expectation.json_schema)
            it "JSON schema" do
              SchemaValidator.new(body, schema_structure).validate!
            end
          end

          if (content_matcher = expectation.json_content_matcher)
            it "JSON content" do
              ContentValidator.new(body, content_matcher).validate!
            end
          end
        end
      end
    end
  end
end
