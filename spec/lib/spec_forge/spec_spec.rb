# frozen_string_literal: true

RSpec.describe SpecForge::Spec do
  let(:name) {}
  let(:path) {}
  let(:method) {}
  let(:content_type) {}
  let(:params) {}
  let(:body) {}
  let(:expectations) {}

  subject(:spec) do
    described_class.new(name:, path:, method:, content_type:, params:, body:, expectations:)
  end

  context "when the minimal is given" do
    let(:name) { Faker::String.random }
    let(:path) { "/users" }

    it "is valid" do
      expect(spec).to be_kind_of(described_class)
    end
  end
end
