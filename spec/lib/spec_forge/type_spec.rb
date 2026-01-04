# frozen_string_literal: true

RSpec.describe SpecForge::Type do
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

  describe ".to_string" do
    context "with single non-nullable types" do
      it "converts Integer to 'integer'" do
        expect(described_class.to_string(Integer)).to eq("integer")
      end

      it "converts String to 'string'" do
        expect(described_class.to_string(String)).to eq("string")
      end

      it "converts Float to 'float'" do
        expect(described_class.to_string(Float)).to eq("float")
      end

      it "converts Hash to 'hash'" do
        expect(described_class.to_string(Hash)).to eq("hash")
      end

      it "converts Array to 'array'" do
        expect(described_class.to_string(Array)).to eq("array")
      end

      it "converts TrueClass to 'boolean'" do
        expect(described_class.to_string(TrueClass)).to eq("boolean")
      end

      it "converts FalseClass to 'boolean'" do
        expect(described_class.to_string(FalseClass)).to eq("boolean")
      end

      it "converts NilClass to 'null'" do
        expect(described_class.to_string(NilClass)).to eq("null")
      end
    end

    context "with nullable types" do
      it "converts [String, NilClass] to '?string'" do
        expect(described_class.to_string(String, NilClass)).to eq("?string")
      end

      it "converts [Integer, NilClass] to '?integer'" do
        expect(described_class.to_string(Integer, NilClass)).to eq("?integer")
      end

      it "converts [Float, NilClass] to '?float'" do
        expect(described_class.to_string(Float, NilClass)).to eq("?float")
      end

      it "converts [Hash, NilClass] to '?hash'" do
        expect(described_class.to_string(Hash, NilClass)).to eq("?hash")
      end

      it "converts [Array, NilClass] to '?array'" do
        expect(described_class.to_string(Array, NilClass)).to eq("?array")
      end

      it "handles NilClass in any position" do
        expect(described_class.to_string(NilClass, String)).to eq("?string")
      end
    end

    context "with boolean types" do
      it "converts [TrueClass, FalseClass] to 'boolean'" do
        expect(described_class.to_string(TrueClass, FalseClass)).to eq("boolean")
      end

      it "converts [FalseClass, TrueClass] to 'boolean' (order doesn't matter)" do
        expect(described_class.to_string(FalseClass, TrueClass)).to eq("boolean")
      end
    end

    context "with nullable booleans" do
      it "converts [TrueClass, FalseClass, NilClass] to '?boolean'" do
        expect(described_class.to_string(TrueClass, FalseClass, NilClass)).to eq("?boolean")
      end

      it "converts [FalseClass, TrueClass, NilClass] to '?boolean' (order doesn't matter)" do
        expect(described_class.to_string(FalseClass, TrueClass, NilClass)).to eq("?boolean")
      end

      it "converts [NilClass, TrueClass, FalseClass] to '?boolean' (NilClass first)" do
        expect(described_class.to_string(NilClass, TrueClass, FalseClass)).to eq("?boolean")
      end
    end

    context "with multiple non-nil types" do
      it "returns array of type strings for [String, Integer]" do
        result = described_class.to_string(String, Integer)
        expect(result).to match_array(["string", "integer"])
      end

      it "returns array for [String, Integer, Hash]" do
        result = described_class.to_string(String, Integer, Hash)
        expect(result).to match_array(["string", "integer", "hash"])
      end

      it "returns array for [Float, String]" do
        result = described_class.to_string(Float, String)
        expect(result).to match_array(["float", "string"])
      end
    end

    context "with multiple types including NilClass" do
      it "strips NilClass and returns array for [String, Integer, NilClass]" do
        result = described_class.to_string(String, Integer, NilClass)
        expect(result).to match_array(["?string", "?integer"])
      end

      it "strips NilClass and returns array for [Hash, Array, NilClass]" do
        result = described_class.to_string(Hash, Array, NilClass)
        expect(result).to match_array(["?hash", "?array"])
      end
    end

    context "edge cases" do
      it "handles duplicate types with uniq" do
        expect(described_class.to_string(String, String)).to eq("string")
      end

      it "handles duplicate types in array result" do
        result = described_class.to_string(String, String, Integer)
        expect(result).to match_array(["string", "integer"])
      end

      it "handles TrueClass/FalseClass duplicates" do
        expect(described_class.to_string(TrueClass, TrueClass, FalseClass, FalseClass)).to eq("boolean")
      end
    end
  end
end
