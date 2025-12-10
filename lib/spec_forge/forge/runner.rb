# frozen_string_literal: true

module SpecForge
  module Forge
    class Runner
      def self.setup
        # Disable autorun because RSpec does it
        RSpec::Core::Runner.disable_autorun!

        # Allows modifying the error backtrace reporting within rspec
        RSpec.configuration.instance_variable_set(:@backtrace_formatter, BacktraceFormatter)
      end

      def initialize(cli_args = [])
        options = RSpec::Core::ConfigurationOptions.new(cli_args)

        @output_io = IO.new
        @error_io = IO.new

        @world = RSpec::Core::World.new
        @runner = RSpec::Core::Runner.new(options, world: @world)
        @runner.configure(@error_io, @output_io)

        @example_groups = []
      end

      def run
        @runner.run_specs(@world.ordered_example_groups)
      end

      def build
      end

      private

      def describe
        # This is just like writing a normal RSpec test, except with loops ;)
        RSpec.describe(forge.name) do
          # Onto the actual expectation itself
          describe(expectation.name) do
            # Set metadata for the example group for error reporting
            Metadata.set_for_group(spec, expectation, self)

            # Lazily load the constraints
            let(:constraints) { expectation.constraints.as_matchers }

            let(:match_status) { constraints[:status] }
            let(:match_json) { constraints[:json] }
            let(:match_json_class) { be_kind_of(match_json.class) }
            let(:match_headers) { constraints[:headers] }

            # The test itself
            it "" do
              ############################################################
              # Status check
              expect(response.status).to match_status

              ############################################################
              # Headers check
              if match_headers.present?
                match_headers.each do |key, matcher|
                  expect(response.headers).to include(key.downcase => matcher)
                end
              end

              ############################################################
              # JSON check
              if match_json.present?
                case match_json
                when Hash
                  match_json.each do |key, matcher|
                    expect(response.body).to include(key)

                    begin
                      expect(response.body[key]).to matcher
                    rescue RSpec::Expectations::ExpectationNotMetError => e
                      # Add the key that failed to the front of the error message
                      e.message.insert(0, "Key: #{key.in_quotes}\n")
                      raise e
                    end
                  end
                else
                  expect(response.body).to match_json
                end
              end
            end
          end
        end
      end
    end
  end
end
