# frozen_string_literal: true

RSpec.describe SpecForge::Normalizer::Structure do
  let(:input) { {} }

  subject(:structure) { described_class.new(input) }

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

    context "when it is none of the above"

    context "when it is not present?"
  end
end
