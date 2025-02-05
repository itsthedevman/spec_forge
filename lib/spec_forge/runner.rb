# frozen_string_literal: true

module SpecForge
  class Runner
    def initialize(spec)
      define_spec(spec)
    end

    def run
      RSpec::Core::Runner.disable_autorun!
      RSpec::Core::Runner.run([], $stderr, $stdout)
    end

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

    def define_variables(context, expectation)
      expectation.variables.each do |variable_name, attribute|
        context.let(variable_name, &attribute.to_proc)
      end
    end

    def define_examples(context, expectation)
      context.instance_exec(expectation) do |expectation|
        subject(:response) { expectation.http_client.call }

        constraints = expectation.constraints
        expected_status = constraints.status.resolve
        expected_json = constraints.json.resolve.deep_stringify_keys

        # Status check
        it "expects the response to return a status code of #{expected_status}" do
          expect(response.status).to eq(expected_status)
        end

        # JSON check
        if expected_json.size > 0
          it "expects the body to return JSON" do
            response_body = response.body

            expect(response_body).to be_kind_of(Hash)
            expect(response_body).to include(expected_json)
          end
        end
      end
    end
  end
end
