# frozen_string_literal: true

RSpec.describe SpecForge::HTTP do
  describe ".status_code_to_description" do
    let(:code) {}

    subject(:description) { described_class.status_code_to_description(code) }

    context "when the status code is known" do
      let(:code) { 421 }

      it "is expected to return the description" do
        is_expected.to eq("421 Misdirected Request")
      end
    end

    context "when the status code is not known" do
      let(:code) { 420 }

      it "is expected to return a generic description" do
        is_expected.to eq("420 Client Error")
      end
    end
  end
end
