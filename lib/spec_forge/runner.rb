# frozen_string_literal: true

module SpecForge
  class Runner
    class << self
      #
      # Runs any specs
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
        RSpec.describe(spec_forge.name) do
          spec_forge.expectations.each do |expectation|
            describe(expectation.name) do
              # Define the example group
              request = expectation.http_client.request

              context "#{request.http_method} #{request.url}" do
                constraints = expectation.constraints

                let!(:expected_status) { constraints.status.resolve }
                let!(:expected_json) { constraints.json.resolve.deep_stringify_keys }

                subject(:response) { expectation.http_client.call }

                it do
                  # Status check
                  expect(response.status).to eq(expected_status)

                  # JSON check
                  if constraints.json.size > 0
                    expect(response.body).to be_kind_of(Hash)
                    expect(response.body).to include(expected_json)
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
