# frozen_string_literal: true

RSpec.describe SpecForge::CLI::Run do
  describe "#extract_filter" do
    let(:input) { "" }

    subject(:filtered) { described_class.new([input], {}).send(:extract_filter, input) }

    context "and the filter is for an expectation" do
      let(:input) { "people:show:'GET /people'" }

      it "is extract to extract the pieces" do
        expect(filtered).to eq(
          file_name: "people",
          spec_name: "show",
          expectation_name: "GET /people"
        )
      end
    end

    context "and the filter is for an expectation and it includes a colon" do
      let(:input) { "people:show:'GET /people/:id - Get: People'" }

      it "is extract to extract the pieces" do
        expect(filtered).to eq(
          file_name: "people",
          spec_name: "show",
          expectation_name: "GET /people/:id - Get: People"
        )
      end
    end
  end
end
