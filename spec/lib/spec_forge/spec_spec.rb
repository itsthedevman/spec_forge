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

  describe ".filter_specs" do
    let(:input) do
      [
        {
          name: "spec_1",
          file_path: "",
          file_name: "specs",
          line_number: 0,
          url: "/specs",
          expectations: [
            {expect: {status: 200}},
            {expect: {status: 200}}
          ]
        },
        {
          name: "spec_2",
          file_path: "",
          file_name: "specs",
          line_number: 0,
          url: "/specs_2",
          expectations: [
            {expect: {status: 200}},
            {expect: {status: 200}}
          ]
        },
        {
          name: "other_spec_1",
          file_path: "",
          file_name: "other_specs",
          line_number: 0,
          url: "/other_specs",
          expectations: [
            {expect: {status: 200}},
            {expect: {status: 200}}
          ]
        },
        {
          name: "other_spec_2",
          file_path: "",
          file_name: "other_specs",
          line_number: 0,
          url: "/other_specs_2",
          expectations: [
            {
              name: "named_expectation",
              expect: {status: 200}
            },
            {expect: {status: 200}}
          ]
        }
      ]
    end

    let(:specs) { input.map { |i| described_class.new(**i) } }

    let(:file_name) {}
    let(:spec_name) {}
    let(:expectation_name) {}

    subject(:filtered) do
      described_class.filter_specs(specs, file_name:, spec_name:, expectation_name:)
    end

    context "when filtering for a file" do
      let(:file_name) { "specs" }

      it "is expected to return the specs with the matching filename" do
        expect(filtered.size).to eq(2)

        # Ensuring they were not modified
        expect(filtered.flat_map(&:expectations).size).to eq(4) # 2 each
      end
    end

    context "when filtering for a spec" do
      let(:file_name) { "specs" }
      let(:spec_name) { "spec_2" }

      it "is expected to return the specs with the matching spec name" do
        expect(filtered.size).to eq(1)

        # Ensuring they were not modified
        expect(filtered.first.expectations.size).to eq(2)
      end
    end

    context "when filtering for an example" do
      let(:file_name) { "other_specs" }
      let(:spec_name) { "other_spec_2" }
      let(:expectation_name) { "GET /other_specs_2 - named_expectation" }

      it "is expected to return the specs with the matching spec name" do
        expect(filtered.size).to eq(1)

        # Ensuring they were modified
        expect(filtered.first.expectations.size).to eq(1)
      end
    end

    context "when filtering by an expectation and the spec is not provided" do
      let(:expectation_name) { "GET /other_specs_2 - named_expectation" }

      it do
        expect { filtered }.to raise_error(ArgumentError)
      end
    end

    context "when filtering by a spec and the filename is not provided" do
      let(:spec_name) { "spec_2" }

      it do
        expect { filtered }.to raise_error(ArgumentError)
      end
    end
  end
end
