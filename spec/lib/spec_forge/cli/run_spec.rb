# frozen_string_literal: true

RSpec.describe SpecForge::CLI::Run do
  describe "#extract_filter" do
    let(:input) { "" }

    subject(:filtered) { described_class.new([input], {}).send(:extract_filter, input) }

    context "when the filter is for a file" do
      let(:input) { "people" }

      it "is expected to extract the pieces" do
        expect(filtered).to eq(
          file_name: "people",
          spec_name: nil,
          expectation_name: nil
        )
      end
    end

    context "when the filter is for a spec" do
      let(:input) { "people:show" }

      it "is expected to extract the pieces" do
        expect(filtered).to eq(
          file_name: "people",
          spec_name: "show",
          expectation_name: nil
        )
      end
    end

    context "when the filter is for an expectation" do
      let(:input) { "people:show:'GET /people'" }

      it "is expected to extract the pieces" do
        expect(filtered).to eq(
          file_name: "people",
          spec_name: "show",
          expectation_name: "GET /people"
        )
      end
    end

    context "when the filter is for an expectation and it includes a colon" do
      let(:input) { "people:show:'GET /people/:id - Get: People'" }

      it "is expected to extract the pieces" do
        expect(filtered).to eq(
          file_name: "people",
          spec_name: "show",
          expectation_name: "GET /people/:id - Get: People"
        )
      end
    end
  end
end
