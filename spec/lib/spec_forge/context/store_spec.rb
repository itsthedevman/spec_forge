# frozen_string_literal: true

RSpec.describe SpecForge::Context::Store do
  subject(:store) { described_class.new }

  describe "#[]" do
    subject(:entry) { store["my_id"] }

    context "when the ID exists" do
      before { store.store("my_id", scope: :file, request: {}, variables: {}, response: {}) }

      it "is expected to return store entry" do
        is_expected.not_to be(nil)
      end
    end

    context "when the ID does not exist" do
      it "is expected to return nil" do
        is_expected.to be(nil)
      end
    end
  end

  describe "#store" do
    it "is expected to store the data as an entry" do
      store.store("my_id", scope: :file, request: {}, variables: {}, response: {})

      expect(store["my_id"]).to be_kind_of(described_class::Entry)
    end
  end

  describe "#clear_scope" do
    before do
      store.store("my_file_id", scope: :file, request: {}, variables: {}, response: {})
      store.store("my_spec_id", scope: :spec, request: {}, variables: {}, response: {})
    end

    context "when the scope is 'file'" do
      it "is expected to clear all" do
        store.clear_scope
        expect(store.size).to eq(0)
      end
    end

    context "when the scope is 'spec'" do
      it "is expected to clear all" do
        store.clear_scope(:spec)
        expect(store.size).to eq(1)
      end
    end

    context "when the scope is neither" do
      it do
        expect { scope.clear_scope(:noop) }.to raise_error(ArgumentError)
      end
    end
  end
end
