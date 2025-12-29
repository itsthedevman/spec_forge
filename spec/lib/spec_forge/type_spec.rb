# frozen_string_literal: true

RSpec.describe SpecForge::Type do
  let(:object) {}

  describe ".hash?" do
    subject(:is_hash) { described_class.hash?(object) }

    context "when the object is a Hash" do
      let(:object) { {} }

      it { is_expected.to be(true) }
    end

    context "when the object is a ResolvableHash" do
      let(:object) { SpecForge::Attribute.from({}) }

      it { is_expected.to be(true) }
    end

    context "when the object is neither" do
      let(:object) { "neither" }

      it { is_expected.to be(false) }
    end
  end

  describe ".array?" do
    subject(:is_array) { described_class.array?(object) }

    context "when the object is a Array" do
      let(:object) { [] }

      it { is_expected.to be(true) }
    end

    context "when the object is a ResolvableArray" do
      let(:object) { SpecForge::Attribute.from([]) }

      it { is_expected.to be(true) }
    end

    context "when the object is neither" do
      let(:object) { "neither" }

      it { is_expected.to be(false) }
    end
  end

  describe ".from_string" do
    context "with basic types" do
      it "converts string types" do
        expect(described_class.from_string("string")).to eq([String])
      end

      it "converts integer types" do
        expect(described_class.from_string("integer")).to eq([Integer])
      end

      it "converts float types" do
        expect(described_class.from_string("float")).to eq([Float])
      end

      it "converts array types" do
        expect(described_class.from_string("array")).to eq([Array])
      end

      it "converts hash types" do
        expect(described_class.from_string("hash")).to eq([Hash])
      end

      it "converts null types" do
        expect(described_class.from_string("null")).to eq([NilClass])
      end
    end

    context "with composite types" do
      it "expands number to Integer and Float" do
        expect(described_class.from_string("number"))
          .to contain_exactly(Integer, Float)
      end

      it "expands boolean to TrueClass and FalseClass" do
        expect(described_class.from_string("boolean"))
          .to contain_exactly(TrueClass, FalseClass)
      end
    end

    context "with type aliases" do
      it "treats numeric as an alias for number" do
        expect(described_class.from_string("numeric"))
          .to contain_exactly(Integer, Float)
      end

      it "treats bool as an alias for boolean" do
        expect(described_class.from_string("bool"))
          .to contain_exactly(TrueClass, FalseClass)
      end

      it "treats object as an alias for hash" do
        expect(described_class.from_string("object")).to eq([Hash])
      end

      it "treats nil as an alias for null" do
        expect(described_class.from_string("nil")).to eq([NilClass])
      end
    end

    context "with nullable types" do
      it "adds NilClass to nullable strings" do
        expect(described_class.from_string("?string"))
          .to contain_exactly(String, NilClass)
      end

      it "adds NilClass to nullable integers" do
        expect(described_class.from_string("?integer"))
          .to contain_exactly(Integer, NilClass)
      end

      it "adds NilClass to nullable floats" do
        expect(described_class.from_string("?float"))
          .to contain_exactly(Float, NilClass)
      end

      it "adds NilClass to nullable numbers" do
        expect(described_class.from_string("?number"))
          .to contain_exactly(Integer, Float, NilClass)
      end

      it "adds NilClass to nullable booleans" do
        expect(described_class.from_string("?boolean"))
          .to contain_exactly(TrueClass, FalseClass, NilClass)
      end

      it "adds NilClass to nullable arrays" do
        expect(described_class.from_string("?array"))
          .to contain_exactly(Array, NilClass)
      end

      it "adds NilClass to nullable hashes" do
        expect(described_class.from_string("?hash"))
          .to contain_exactly(Hash, NilClass)
      end

      it "handles nullable null without duplicating NilClass" do
        result = described_class.from_string("?null")
        expect(result).to contain_exactly(NilClass)
      end

      it "handles nullable nil without duplicating NilClass" do
        result = described_class.from_string("?nil")
        expect(result).to contain_exactly(NilClass)
      end
    end

    context "with nullable aliases" do
      it "handles nullable numeric" do
        expect(described_class.from_string("?numeric"))
          .to contain_exactly(Integer, Float, NilClass)
      end

      it "handles nullable bool" do
        expect(described_class.from_string("?bool"))
          .to contain_exactly(TrueClass, FalseClass, NilClass)
      end

      it "handles nullable object" do
        expect(described_class.from_string("?object"))
          .to contain_exactly(Hash, NilClass)
      end
    end

    context "with invalid types" do
      it "raises ArgumentError with helpful message" do
        expect { described_class.from_string("invalid") }
          .to raise_error(
            ArgumentError,
            /Unknown type: "invalid".*Valid types: string, number\/numeric, integer, float, boolean\/bool, array, hash\/object, null\/nil/
          )
      end

      it "raises ArgumentError for nullable invalid types" do
        expect { described_class.from_string("?invalid") }
          .to raise_error(ArgumentError, /Unknown type: "invalid"/)
      end

      it "raises ArgumentError for typos" do
        expect { described_class.from_string("strig") }
          .to raise_error(ArgumentError, /Unknown type: "strig"/)
      end

      it "raises ArgumentError for nil input" do
        expect { described_class.from_string(nil) }
          .to raise_error(ArgumentError, /Input is nil/)
      end
    end
  end
end

RSpec.describe HashLike do
  subject(:is_hash) do
    case object
    when HashLike
      true
    else
      false
    end
  end

  context "when the object is a Hash" do
    let(:object) { {} }

    it { is_expected.to be(true) }
  end

  context "when the object is a ResolvableHash" do
    let(:object) { SpecForge::Attribute.from({}) }

    it { is_expected.to be(true) }
  end

  context "when the object is neither" do
    let(:object) { "neither" }

    it { is_expected.to be(false) }
  end
end

RSpec.describe ArrayLike do
  subject(:is_array) do
    case object
    when ArrayLike
      true
    else
      false
    end
  end

  context "when the object is a Array" do
    let(:object) { [] }

    it { is_expected.to be(true) }
  end

  context "when the object is a ResolvableArray" do
    let(:object) { SpecForge::Attribute.from([]) }

    it { is_expected.to be(true) }
  end

  context "when the object is neither" do
    let(:object) { "neither" }

    it { is_expected.to be(false) }
  end
end
