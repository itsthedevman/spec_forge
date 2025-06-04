# frozen_string_literal: true

RSpec.describe SpecForge::Context::Store do
  subject(:store) { described_class.new }

  describe "#[]" do
    subject(:entry) { store["my_id"] }

    context "when the ID exists" do
      before { store.set("my_id", scope: :file, request: {}, variables: {}, response: {}) }

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

  describe "#set" do
    it "is expected to store the data as an entry" do
      store.set("my_id", scope: :file, request: {}, variables: {}, response: {})

      expect(store["my_id"]).to be_kind_of(described_class::Entry)
    end

    it "is expected to allow any key and attributes" do
      store.set("my_data", scope: :file, foo: 1, bar: 2, baz: {key: 3})

      expect(store["my_data"]).to be_kind_of(described_class::Entry)
      expect(store["my_data"]).to have_attributes(
        scope: :file,
        foo: 1,
        bar: 2,
        baz: {key: 3}
      )
    end
  end

  describe "#clear" do
    before do
      store.set("my_file_id", scope: :file, request: {}, variables: {}, response: {})
      store.set("my_spec_id", scope: :spec, request: {}, variables: {}, response: {})
    end

    it "is expected to clear all" do
      store.clear
      expect(store.size).to eq(0)
    end
  end

  describe "#clear_specs" do
    before do
      store.set("my_file_id", scope: :file, request: {}, variables: {}, response: {})
      store.set("my_spec_id", scope: :spec, request: {}, variables: {}, response: {})
    end

    it "is expected to clear all specs" do
      store.clear_specs
      expect(store.size).to eq(1)
    end
  end
end
