# frozen_string_literal: true

module SpecForge
  class Runner
    #
    # Creates a spec runner and defines the spec with RSpec
    #
    # @param spec [Spec] The spec to run
    #
    def initialize(spec)
      define_spec(spec)
    end

    #
    # Runs any RSpec specs
    #
    def run
      RSpec::Core::Runner.disable_autorun!
      RSpec::Core::Runner.run([], $stderr, $stdout)
    end

    #
    # Defines a spec with RSpec
    #
    # @param spec_forge [Spec] The spec to define
    #
    def define_spec(spec_forge)
      runner_forge = self

      RSpec.describe(spec_forge.name) do
        spec_forge.expectations.each do |expectation_forge|
          describe(expectation_forge.name) do
            runner_forge.define_examples(self, expectation_forge)
          end
        end
      end
    end

    #
    # Defines the expectation itself using the constraint
    #
    # @param context [RSpec::ExampleGroup] The RSpec example group for this spec
    # @param expectation [Expectation] The expectation that holds the constraint
    #
    def define_examples(context, expectation)
      context.instance_exec(expectation) do |expectation|
        before(:all) do
          # Ensures the only one API call occurs per expectation
          @response = expectation.http_client.call
        end

        subject(:response) { @response }

        # Define the example group
        request = expectation.http_client.request
        context "#{request.http_method} #{request.url}" do
          constraints = expectation.constraints

          let(:expected_status) { constraints.status.resolve }
          let(:expected_json) { constraints.json.resolve }

          # Status check
          it do
            expect(response.status).to eq(expected_status)
          end

          # JSON check
          if constraints.json.size > 0
            it do
              expect(response.body).to be_kind_of(Hash)
            end

            it do
              expect(response.body).to include(expected_json)
            end
          end
        end
      end
    end
  end
end
