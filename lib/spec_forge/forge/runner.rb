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
        assayer = Assayer.new(forge)

        RSpec::Core::ExampleGroup.describe(step.source.to_s) do
          ############################################################
          # Status check
          if (status_matcher = expectation.status_matcher)
            it "Status" do
              assayer.response_status(self, status_matcher)
            end
          end

          ############################################################
          # Headers check
          if (headers_matcher = expectation.headers_matcher)
            it "Headers" do
              assayer.response_headers(self, headers_matcher)
            end
          end

          ############################################################
          # JSON checks
          if (json_size_matcher = expectation.json_size_matcher)
            it "Size" do
              assayer.response_json_size(self, json_size_matcher)
            end
          end

          if (json_shape_matcher = expectation.json_shape_matcher)
            it "Shape" do
              assayer.response_json_shape(self, json_shape_matcher)
            end
          end
        end
      end
    end
  end
end
