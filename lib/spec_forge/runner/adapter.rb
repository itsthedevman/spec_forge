# frozen_string_literal: true

module SpecForge
  class Runner
    class Adapter
      include Singleton

      def self.setup(forges)
        # Defines the forges with RSpec
        forges.each { |forge| instance.describe(forge) }

        # Remove any arguments as RSpec will attempt to use them
        ARGV.clear

        # Allows modifying the error backtrace reporting within rspec
        RSpec.configuration.instance_variable_set(:@backtrace_formatter, BacktraceFormatter)

        # Listen for passed/failed events to trigger the "after_each" callback
        RSpec.configuration.reporter.register_listener(
          Listener.instance,
          :example_passed, :example_failed
        )
      end

      def self.run(exit_on_finish: false)
        if exit_on_finish
          RSpec::Core::Runner.invoke
        else
          RSpec::Core::Runner.run([])
        end
      end

      ##########################################################################

      #
      # Defines RSpec examples for a specific forge
      # Creates the test structure for a single forge file
      #
      # @param forge [Forge] The forge to define
      #
      def describe(forge)
        # This is just like writing a normal RSpec test, except with loops ;)
        RSpec.describe(forge.name) do
          # Callback for the file
          before(:context) { Callbacks.before_file(forge) }
          after(:context) { Callbacks.after_file(forge) }

          # Specs
          forge.specs.each do |spec|
            # Describe the spec
            describe(spec.name) do
              # Request data is for the spec and contains the base and overlays
              let!(:request_data) { forge.request[spec.id] }

              # The HTTP client for the spec
              let!(:http_client) { HTTP::Client.new(**request_data[:base]) }

              # Callback for the spec
              before(:context) { Callbacks.before_spec(forge, spec) }
              after(:context) { Callbacks.after_spec(forge, spec) }

              # Expectations
              spec.expectations.each do |expectation|
                # Onto the actual expectation itself
                describe(expectation.name) do
                  # Set metadata for the example group for error reporting
                  Metadata.set_for_group(spec, expectation, self)

                  # Lazily load the constraints
                  let(:constraints) { expectation.constraints.as_matchers }

                  let(:match_status) { constraints[:status] }
                  let(:match_json) { constraints[:json] }
                  let(:match_json_class) { be_kind_of(match_json.class) }

                  # The request for the test itself. Overlays the expectation's data if it exists
                  let(:request) do
                    request = request_data[:base]

                    if (overlay = request_data[:overlay][expectation.id])
                      request = request.deep_merge(overlay)
                    end

                    HTTP::Request.new(**request)
                  end

                  # The Faraday response
                  subject(:response) { http_client.call(request) }

                  # Callbacks for the expectation
                  before :each do
                    Callbacks.before_expectation(
                      forge, spec, expectation, self, RSpec.current_example
                    )
                  end

                  # The 'after_expectation' callback is handled by Listener due to RSpec not
                  # reporting the example's status until after the describe block has finished.
                  after :each do
                    # However, the downside about having the callback triggered later is that RSpec
                    # will have reset the memoized let variables back to nil.
                    # This causes an issue when an expectation goes to store the state, it will end
                    # up re-calling the various variables and triggering another HTTP request.
                    # Since the variables are still memoized in this hook, it is the perfect
                    # time to store the referenced to them.
                    State.set(response:)
                  end

                  # The test itself
                  it(expectation.constraints.description) do
                    if spec.debug? || expectation.debug?
                      Callbacks.on_debug(forge, spec, expectation, self)
                    end

                    # Status check
                    expect(response.status).to match_status

                    # JSON check
                    if match_json.present?
                      expect(response.body).to match_json_class

                      case match_json
                      when Hash
                        # Check per key for easier debugging
                        match_json.each do |key, matcher|
                          expect(response.body).to have_key(key)
                          expect(response.body[key]).to matcher
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
    end
  end
end
