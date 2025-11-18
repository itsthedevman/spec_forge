# frozen_string_literal: true

RSpec.describe SpecForge::Loader do
  let(:path) { "" }
  let(:tags) { [] }
  let(:skip_tags) { [] }

  subject(:loader) { described_class.new(path:, tags:, skip_tags:) }

  context "when no path is provided" do
    it "is expected to load from the blueprints/ directory" do
    end
  end

  context "when a file path is provided" do
  end

  context "when a directory path is provided" do
  end

  context "when tags are provided"

  context "when skip_tags are provided"

  context "when both tags and skip_tags are provided"
end
