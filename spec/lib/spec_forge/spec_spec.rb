# frozen_string_literal: true

RSpec.describe SpecForge::Spec do
  let(:name) { Faker::String.random }
  let(:path) { "/users" }
  let(:method) {}
  let(:content_type) {}
  let(:params) {}
  let(:body) {}
  let(:expectations) {}

  subject(:spec) do
    described_class.new(name:, path:, method:, content_type:, params:, body:, expectations:)
  end

  describe ".load_and_run" do
    it "cannot be ran via RSpec. Run `bin/integration_specs`" do
      expect(true).to be(true)
    end
  end

  describe ".load_from_path" do
    let(:path) { SpecForge.root.join("spec", ".spec_forge", "specs", "**/*.yml") }

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
      context "and they are valid" do
        let(:expectations) do
          [
            {status: 400},
            {status: 200}
          ]
        end

        it "stores them in as an Expectation" do
          expect(spec.expectations).to include(
            be_kind_of(described_class::Expectation),
            be_kind_of(described_class::Expectation)
          )
        end
      end

      context "and they are not valid" do
        let(:expectations) do
          [
            Faker::String.random,
            Faker::Number.positive
          ]
        end

        it "stores them in as an Expectation regardless" do
          expect(spec.expectations).to include(
            be_kind_of(described_class::Expectation),
            be_kind_of(described_class::Expectation)
          )
        end
      end
    end
  end
end
