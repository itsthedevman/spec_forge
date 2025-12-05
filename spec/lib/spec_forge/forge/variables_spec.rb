# frozen_string_literal: true

RSpec.describe SpecForge::Forge::Variables do
  subject(:variables) { described_class.new(static:, dynamic:) }

  let(:static) { {} }
  let(:dynamic) { {} }

  describe "#initialize" do
    context "with no arguments" do
      subject(:variables) { described_class.new }

      it "initializes with empty static and dynamic hashes" do
        expect(variables[:anything]).to be_nil
      end
    end

    context "with static variables" do
      let(:static) { {foo: "bar"} }

      it "stores static variables" do
        expect(variables[:foo]).to eq("bar")
      end

      it "deep duplicates static variables" do
        original = {nested: {value: "original"}}
        vars = described_class.new(static: original)

        original[:nested][:value] = "modified"

        expect(vars[:nested][:value]).to eq("original")
      end
    end

    context "with dynamic variables" do
      let(:dynamic) { {baz: "qux"} }

      it "stores dynamic variables" do
        expect(variables[:baz]).to eq("qux")
      end

      it "deep duplicates dynamic variables" do
        original = {nested: {value: "original"}}
        vars = described_class.new(dynamic: original)

        original[:nested][:value] = "modified"

        expect(vars[:nested][:value]).to eq("original")
      end
    end
  end

  describe "#[]" do
    let(:static) { {shared: "static_value", static_only: "from_static"} }
    let(:dynamic) { {shared: "dynamic_value", dynamic_only: "from_dynamic"} }

    it "returns dynamic value when key exists in both" do
      expect(variables[:shared]).to eq("dynamic_value")
    end

    it "returns static value when key only exists in static" do
      expect(variables[:static_only]).to eq("from_static")
    end

    it "returns dynamic value when key only exists in dynamic" do
      expect(variables[:dynamic_only]).to eq("from_dynamic")
    end

    it "returns nil when key does not exist" do
      expect(variables[:nonexistent]).to be_nil
    end

    it "supports string keys via indifferent access" do
      expect(variables["shared"]).to eq("dynamic_value")
      expect(variables["static_only"]).to eq("from_static")
    end
  end

  describe "#fetch" do
    let(:static) { {key: "value"} }

    it "is aliased to #[]" do
      expect(variables.fetch(:key)).to eq("value")
    end
  end

  describe "#[]=" do
    it "stores value in dynamic hash" do
      variables[:new_key] = "new_value"

      expect(variables[:new_key]).to eq("new_value")
    end

    it "overrides static values with dynamic" do
      static_vars = described_class.new(static: {key: "static"})

      static_vars[:key] = "dynamic"

      expect(static_vars[:key]).to eq("dynamic")
    end

    it "supports string keys via indifferent access" do
      variables["string_key"] = "string_value"

      expect(variables[:string_key]).to eq("string_value")
    end
  end

  describe "#store" do
    it "is aliased to #[]=" do
      variables.store(:stored_key, "stored_value")

      expect(variables[:stored_key]).to eq("stored_value")
    end
  end

  describe "#clear" do
    let(:static) { {static_key: "static_value"} }
    let(:dynamic) { {dynamic_key: "dynamic_value"} }

    it "clears dynamic variables" do
      variables.clear

      expect(variables[:dynamic_key]).to be_nil
    end

    it "preserves static variables" do
      variables.clear

      expect(variables[:static_key]).to eq("static_value")
    end

    it "allows dynamic values to be set again after clear" do
      variables.clear
      variables[:new_dynamic] = "new_value"

      expect(variables[:new_dynamic]).to eq("new_value")
    end
  end
end
