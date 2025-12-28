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
        entry[:examples].partition { |ex| ex[:status] == "passed" }
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
            it "Response status code" do
              assayer.response_status(self, status_matcher)
            end
          end

          ############################################################
          # Headers check
          if (headers_matcher = expectation.headers_matcher)
            it "Response headers" do
              assayer.response_headers(self, headers_matcher)
            end
          end

          ############################################################
          # JSON check
          if (json_size_matcher = expectation.json_size_matcher)
            it "Response body size" do
              assayer.response_json_size(self, json_size_matcher)
            end
          end

          if (json_structure_matcher = expectation.json_structure_matcher)
            it "Response body structure" do
              assayer.response_json_structure(self, json_structure_matcher)
            end
          end

          # if (matcher = json_matchers[:pattern])
          #   it { assayer.response_json_pattern(self, matcher) }
          # end

          # if (matcher = json_matchers[:content])
          #   it { assayer.response_json_content(self, matcher) }
          # end
        end
      end
    end
  end
end

# Handle when a looped test fails
# rescue RSpec::Expectations::ExpectationNotMetError => e
#         # Add the key that failed to the front of the error message
#         e.message.insert(0, "Key: #{key.in_quotes}\n")
#         raise e
