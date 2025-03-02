# frozen_string_literal: true

RSpec.describe SpecForge::Spec do
  let(:name) { Faker::String.random }
  let(:url) { "/users" }
  let(:method) {}
  let(:headers) {}
  let(:variables) {}
  let(:query) {}
  let(:body) {}
  let(:expectations) { [] }

  subject(:spec) do
    described_class.new(
      name:,
      file_path: "", file_name: "", line_number: 0,
      url:, method:, headers:,
      variables:, query:, body:, expectations:
    )
  end

  describe "#initialize" do
    context "when the minimal is given" do
      it "is valid" do
        expect(spec).to be_kind_of(described_class)
      end
    end

    context "when 'expectations' are given" do
      let(:expectations) do
        [
          {expect: {status: 200}},
          {expect: {status: 400}}
        ]
      end

      it "is expected to convert them to Expectations" do
        expect(spec.expectations).to include(
          be_kind_of(described_class::Expectation),
          be_kind_of(described_class::Expectation)
        )
      end
    end
  end
end
