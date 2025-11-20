# frozen_string_literal: true

RSpec.describe SpecForge::Documentation::Generators::OpenAPI do
  describe ".[]" do
    let(:version) { "" }

    subject(:result) { described_class[version] }

    context "when the version is major only" do
      let(:version) { "3" }

      it "is expected to return the related class" do
        is_expected.to eq(described_class::V30)
      end
    end

    context "when the version is major and minor" do
      let(:version) { "3.0" }

      it "is expected to return the related class" do
        is_expected.to eq(described_class::V30)
      end
    end

    context "when the version has a major, minor, and patch" do
      let(:version) { "3.0.0" }

      it "is expected to return the related class" do
        is_expected.to eq(described_class::V30)
      end
    end

    context "when the version does not exist" do
      let(:version) { "2.0" }

      it do
        expect { result }.to raise_error(
          ArgumentError,
          "Invalid OpenAPI version provided: \"2.0.0\""
        )
      end
    end
  end
end
