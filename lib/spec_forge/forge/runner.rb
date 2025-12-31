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
              headers_matcher.each do |key, matcher|
                expect(headers).to have_key(key)
                expect(headers[key]).to(matcher)
              end

              display.success("Headers", indent: 1)
            end
          end

          ############################################################
          # JSON checks
          if (json_size_matcher = expectation.json_size_matcher)
            it "Size" do
              expect(body.size).to json_size_matcher

              display.success("Size", indent: 1)
            end
          end

          if (structure = expectation.json_shape_structure)
            it "Shape" do
              ShapeValidator.new(body, structure).validate!

              display.success("Shape", indent: 1)
            end
          end
        end
      end
    end
  end
end
