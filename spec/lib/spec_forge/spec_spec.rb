# frozen_string_literal: true

RSpec.describe SpecForge::Spec do
  let(:name) { Faker::String.random }
  let(:url) { "/users" }
  let(:method) {}
  let(:content_type) {}
  let(:variables) {}
  let(:query) {}
  let(:body) {}
  let(:expectations) { [] }

  subject(:spec) do
    described_class.new(
      name:, url:, method:, content_type:,
      variables:, query:, body:, expectations:
    )
  end

  describe ".load_and_run" do
    it "cannot be ran via RSpec. Run `bin/test_runner`" do
      expect(true).to be(true)
    end
  end

  describe ".load_from_path" do
    let(:path) { SpecForge.forge.join("specs", "**/*.yml") }

    subject(:specs) { described_class.load_from_path(path) }

    context "when all specs are valid" do
      it "loads the specs" do
        expect(specs).to be_kind_of(Array)
        expect(specs.size).to be > 0

        expect(specs.first).to be_kind_of(described_class)
      end
    end
  end

  describe "#initialize" do
    context "when the minimal is given" do
      it "is valid" do
        expect(spec).to be_kind_of(described_class)
      end
    end

    context "when 'expectations' are given" do
      context "and it is an array" do
        let(:expectations) do
          [
            {status: 400},
            {expect: {status: 200}}
          ]
        end

        it "stores them in as an Expectation regardless of validity" do
          expect(spec.expectations).to include(
            be_kind_of(described_class::Expectation),
            be_kind_of(described_class::Expectation)
          )
        end
      end
    end

    context "when 'variables' are given" do
      context "and it is a hash" do
        let(:variables) do
          {id: 1, name: "Billy"}
        end

        context "and the expectations do not have variables" do
          let(:expectations) do
            [{expect: {status: 200}}]
          end

          it "passes them into the expectations" do
            expect(spec.expectations.first.variables).to eq([])
          end
        end

        context "and the expectations have variables as well" do
          let(:expectations) do
            [{expect: {status: 200}, variables: {id: 2}}]
          end

          it "is expected to merge and be overwritten by the expectation variables" do
            expect(spec.expectations.first.variables.resolve).to include(
              id: 2, name: "Billy"
            )
          end
        end
      end

      context "and it is not a hash" do
        let(:variables) { [] }

        it do
          expect { spec }.to raise_error(
            SpecForge::InvalidTypeError,
            "Expected Hash, got Array for 'variables' on spec"
          )
        end
      end
    end
  end
end
