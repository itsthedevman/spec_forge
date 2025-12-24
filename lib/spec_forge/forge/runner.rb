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
        response = forge.variables[:response]

        RSpec::Core::ExampleGroup.describe(step.source.to_s) do
          # The test itself
          it(expectation.description) do
            ############################################################
            # Status check
            if (matcher = expectation.status_matcher)
              expect(response.status).to matcher
              forge.display.success(HTTP.status_code_to_description(response.status), indent: 1)
            end

            ############################################################
            # Headers check
            if (headers_matcher = expectation.headers_matcher)
              headers = response.headers
              headers_matcher.each do |key, matcher|
                key = key.to_s

                expect(headers).to have_key(key)
                expect(headers[key]).to matcher

                forge.display.success("#{key.in_quotes} #{matcher.description}", indent: 1)
              end
            end

            ############################################################
            # JSON check
            # if match_json.present?
            #   case match_json
            #   when Hash
            #     match_json.each do |key, matcher|
            #       expect(response.body).to include(key)

            #       begin
            #         expect(response.body[key]).to matcher
            #       rescue RSpec::Expectations::ExpectationNotMetError => e
            #         # Add the key that failed to the front of the error message
            #         e.message.insert(0, "Key: #{key.in_quotes}\n")
            #         raise e
            #       end
            #     end
            #   else
            #     expect(response.body).to match_json
            #   end
            # end
          end
        end
      end
    end
  end
end
