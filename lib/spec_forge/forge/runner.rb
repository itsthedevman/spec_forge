# frozen_string_literal: true

module SpecForge
  class Forge
    class Runner
      def self.setup
        # Disable autorun because RSpec does it
        RSpec::Core::Runner.disable_autorun!

        # Allows modifying the error backtrace reporting within rspec
        RSpec.configuration.instance_variable_set(:@backtrace_formatter, BacktraceFormatter)
      end

      def initialize(cli_args = [])
        options = RSpec::Core::ConfigurationOptions.new(cli_args)

        @output_io = StringIO.new
        @error_io = StringIO.new

        @world = RSpec::Core::World.new
        @configuration = RSpec::Core::Configuration.new
        @runner = RSpec::Core::Runner.new(options, @configuration, @world)

        @runner.configure(@error_io, @output_io)
      end

      def run
        @runner.run_specs(@world.ordered_example_groups)
      ensure
        @world.reset
      end

      def build(forge, expectation)
        @world.example_groups << create_example_group(forge, expectation)
      end

      private

      def create_example_group(forge, expectation)
        response = forge.variables[:response]

        RSpec::Core::ExampleGroup.describe do
          # Set metadata for the example group for error reporting
          # Metadata.set_for_group(spec, expectation, self)

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
              headers_matcher.each do |key, matcher|
                expect(response.headers).to include(key.to_s => matcher)
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
