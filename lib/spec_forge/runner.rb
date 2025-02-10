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
            runner_forge.define_variables(self, expectation_forge)
            runner_forge.define_examples(self, expectation_forge)
          end
        end
      end
    end

    #
    # Defines any variables as let statements in RSpec
    #
    # @param context [RSpec::ExampleGroup] The rspec example group for this spec
    # @param expectation [Expectation] The expectation that holds the variables
    #
    def define_variables(context, expectation)
      expectation.variables.each do |variable_name, attribute|
        context.let(variable_name, &attribute.to_proc)
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
        # Ensures the only one API call occurs per expectation
        before(:all) { @response = expectation.http_client.call }

        constraints = expectation.constraints.resolve
        request = expectation.http_client.request

        # Define the example group
        context "#{request.http_method} #{request.url}" do
          subject(:response) { @response }

          # Status check
          expected_status = constraints[:status]
          it "expects the response to return a status code of #{expected_status}" do
            expect(response.status).to eq(expected_status)
          end

          # JSON check
          expected_json = constraints[:json]
          if expected_json.size > 0
            it "expects the body to return valid JSON" do
              expect(response.body).to be_kind_of(Hash)
            end

            it "expects the body to include values" do
              expect(response.body).to include(expected_json)
            end
          end
        end
      end
    end
  end
end
