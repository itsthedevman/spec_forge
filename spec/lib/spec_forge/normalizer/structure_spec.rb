# frozen_string_literal: true

RSpec.describe SpecForge::Normalizer::Structure do
  let(:input) { {} }

  subject(:structure) { described_class.new(input, label: "normalizer") }

  context "when the attribute is nil" do
    let(:input) { {a: nil} }

    it do
      expect { structure }.to raise_error(
        ArgumentError, "Attribute \"a\": Expected String, Array, or Hash. Got nil"
      )
    end
  end

  context "when the attribute is a string (shorthand for a single type)" do
    let(:input) { {a: "integer"} }

    it "is expected to convert" do
      is_expected.to eq({a: {type: Integer}})
    end
  end

  context "when the attribute is an array (shorthand for multiple types)" do
    let(:input) { {a: ["hash", "string"]} }

    it "is expected convert" do
      is_expected.to eq({a: {type: [Hash, String]}})
    end
  end

  context "when the attribute's type is boolean" do
    let(:input) { {a: "boolean"} }

    it "is expected to set the type" do
      is_expected.to eq({a: {type: [TrueClass, FalseClass]}})
    end
  end

  describe "'type' attribute" do
    context "when it is array" do
      let(:input) { {a: {type: ["string", "integer"]}} }

      it "is expected to convert" do
        is_expected.to eq({a: {type: [String, Integer]}})
      end
    end

    context "when it is string" do
      let(:input) { {a: {type: "string"}} }

      it "is expected to convert" do
        is_expected.to eq({a: {type: String}})
      end
    end

    context "when it is a class" do
      let(:input) { {a: {type: NilClass}} }

      it "is expected to keep" do
        is_expected.to eq({a: {type: NilClass}})
      end
    end

    context "when it is not present?" do
      let(:input) { {a: {type: ""}} }

      it do
        expect { structure }.to raise_error(
          SpecForge::Error::InvalidStructureError,
          "Value cannot be blank for \"type\" in \"a\" in \"normalizer\""
        )
      end
    end
  end

  describe "'default' attribute" do
    context "when it is not a String, NilClass, Numeric, Array, Hash, TrueClass, or FalseClass" do
      let(:input) { {a: {type: String, default: OpenStruct.new}} }

      it do
        expect { structure }.to raise_error(
          SpecForge::Error::InvalidStructureError,
          "Expected String, NilClass, Numeric, Array, Hash, TrueClass, or FalseClass, got OpenStruct for \"default\" in \"a\" in \"normalizer\""
        )
      end
    end
  end

  describe "'required' attribute" do
    context "when it is not TrueClass or FalseClass" do
      let(:input) { {a: {type: String, required: "true"}} }

      it do
        expect { structure }.to raise_error(
          SpecForge::Error::InvalidStructureError,
          "Expected TrueClass or FalseClass, got String for \"required\" in \"a\" in \"normalizer\""
        )
      end
    end
  end

  describe "'aliases' attribute" do
    context "when it is not an array" do
      let(:input) { {a: {type: String, aliases: ""}} }

      it do
        expect { structure }.to raise_error(
          SpecForge::Error::InvalidStructureError,
          "Expected Array, got String for \"aliases\" in \"a\" in \"normalizer\""
        )
      end
    end

    context "when it is not an array of strings" do
      let(:input) { {a: {type: String, aliases: [1]}} }

      it do
        expect { structure }.to raise_error(
          SpecForge::Error::InvalidStructureError,
          "Expected String, got Integer for index 0 of \"aliases\" in \"a\" in \"normalizer\""
        )
      end
    end
  end

  describe "'structure' attribute" do
    context "when it is not Hash" do
      let(:input) { {a: {type: String, structure: "true"}} }

      it do
        expect { structure }.to raise_error(
          SpecForge::Error::InvalidStructureError,
          "Expected Hash, got String for \"structure\" in \"a\" in \"normalizer\""
        )
      end
    end
  end

  describe "'validator' attribute" do
    context "when it is not String" do
      let(:input) { {a: {type: String, validator: {}}} }

      it do
        expect { structure }.to raise_error(
          SpecForge::Error::InvalidStructureError,
          "Expected String, got Hash for \"validator\" in \"a\" in \"normalizer\""
        )
      end
    end
  end

  describe "'transformer' attribute" do
    context "when it is not String" do
      let(:input) { {a: {type: String, transformer: {}}} }

      it do
        expect { structure }.to raise_error(
          SpecForge::Error::InvalidStructureError,
          "Expected String, got Hash for \"transformer\" in \"a\" in \"normalizer\""
        )
      end
    end
  end
end
