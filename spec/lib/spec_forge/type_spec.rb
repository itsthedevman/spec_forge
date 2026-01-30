# frozen_string_literal: true

RSpec.describe SpecForge::Type do
  describe ".from_string" do
    context "with basic types" do
      it "converts string types" do
        result = described_class.from_string("string")
        expect(result[:types]).to eq([String])
        expect(result[:optional]).to be false
      end

      it "converts integer types" do
        result = described_class.from_string("integer")
        expect(result[:types]).to eq([Integer])
        expect(result[:optional]).to be false
      end

      it "converts float types" do
        result = described_class.from_string("float")
        expect(result[:types]).to eq([Float])
        expect(result[:optional]).to be false
      end

      it "converts array types" do
        result = described_class.from_string("array")
        expect(result[:types]).to eq([Array])
        expect(result[:optional]).to be false
      end

      it "converts hash types" do
        result = described_class.from_string("hash")
        expect(result[:types]).to eq([Hash])
        expect(result[:optional]).to be false
      end

      it "converts null types" do
        result = described_class.from_string("null")
        expect(result[:types]).to eq([NilClass])
        expect(result[:optional]).to be false
      end
    end

    context "with composite types" do
      it "expands number to Integer and Float" do
        result = described_class.from_string("number")
        expect(result[:types]).to contain_exactly(Integer, Float)
        expect(result[:optional]).to be false
      end

      it "expands boolean to TrueClass and FalseClass" do
        result = described_class.from_string("boolean")
        expect(result[:types]).to contain_exactly(TrueClass, FalseClass)
        expect(result[:optional]).to be false
      end
    end

    context "with type aliases" do
      it "treats numeric as an alias for number" do
        result = described_class.from_string("numeric")
        expect(result[:types]).to contain_exactly(Integer, Float)
        expect(result[:optional]).to be false
      end

      it "treats bool as an alias for boolean" do
        result = described_class.from_string("bool")
        expect(result[:types]).to contain_exactly(TrueClass, FalseClass)
        expect(result[:optional]).to be false
      end

      it "treats object as an alias for hash" do
        result = described_class.from_string("object")
        expect(result[:types]).to eq([Hash])
        expect(result[:optional]).to be false
      end

      it "treats nil as an alias for null" do
        result = described_class.from_string("nil")
        expect(result[:types]).to eq([NilClass])
        expect(result[:optional]).to be false
      end
    end

    context "with nullable types" do
      it "adds NilClass to nullable strings" do
        result = described_class.from_string("?string")
        expect(result[:types]).to contain_exactly(String, NilClass)
        expect(result[:optional]).to be false
      end

      it "adds NilClass to nullable integers" do
        result = described_class.from_string("?integer")
        expect(result[:types]).to contain_exactly(Integer, NilClass)
        expect(result[:optional]).to be false
      end

      it "adds NilClass to nullable floats" do
        result = described_class.from_string("?float")
        expect(result[:types]).to contain_exactly(Float, NilClass)
        expect(result[:optional]).to be false
      end

      it "adds NilClass to nullable numbers" do
        result = described_class.from_string("?number")
        expect(result[:types]).to contain_exactly(Integer, Float, NilClass)
        expect(result[:optional]).to be false
      end

      it "adds NilClass to nullable booleans" do
        result = described_class.from_string("?boolean")
        expect(result[:types]).to contain_exactly(TrueClass, FalseClass, NilClass)
        expect(result[:optional]).to be false
      end

      it "adds NilClass to nullable arrays" do
        result = described_class.from_string("?array")
        expect(result[:types]).to contain_exactly(Array, NilClass)
        expect(result[:optional]).to be false
      end

      it "adds NilClass to nullable hashes" do
        result = described_class.from_string("?hash")
        expect(result[:types]).to contain_exactly(Hash, NilClass)
        expect(result[:optional]).to be false
      end

      it "handles nullable null without duplicating NilClass" do
        result = described_class.from_string("?null")
        expect(result[:types]).to contain_exactly(NilClass)
        expect(result[:optional]).to be false
      end

      it "handles nullable nil without duplicating NilClass" do
        result = described_class.from_string("?nil")
        expect(result[:types]).to contain_exactly(NilClass)
        expect(result[:optional]).to be false
      end
    end

    context "with nullable aliases" do
      it "handles nullable numeric" do
        result = described_class.from_string("?numeric")
        expect(result[:types]).to contain_exactly(Integer, Float, NilClass)
        expect(result[:optional]).to be false
      end

      it "handles nullable bool" do
        result = described_class.from_string("?bool")
        expect(result[:types]).to contain_exactly(TrueClass, FalseClass, NilClass)
        expect(result[:optional]).to be false
      end

      it "handles nullable object" do
        result = described_class.from_string("?object")
        expect(result[:types]).to contain_exactly(Hash, NilClass)
        expect(result[:optional]).to be false
      end
    end

    context "with optional types" do
      it "marks optional strings" do
        result = described_class.from_string("*string")
        expect(result[:types]).to eq([String])
        expect(result[:optional]).to be true
      end

      it "marks optional integers" do
        result = described_class.from_string("*integer")
        expect(result[:types]).to eq([Integer])
        expect(result[:optional]).to be true
      end

      it "marks optional booleans" do
        result = described_class.from_string("*boolean")
        expect(result[:types]).to contain_exactly(TrueClass, FalseClass)
        expect(result[:optional]).to be true
      end

      it "marks optional arrays" do
        result = described_class.from_string("*array")
        expect(result[:types]).to eq([Array])
        expect(result[:optional]).to be true
      end

      it "marks optional hashes" do
        result = described_class.from_string("*hash")
        expect(result[:types]).to eq([Hash])
        expect(result[:optional]).to be true
      end
    end

    context "with combined optional and nullable flags" do
      it "handles *? order (optional nullable string)" do
        result = described_class.from_string("*?string")
        expect(result[:types]).to contain_exactly(String, NilClass)
        expect(result[:optional]).to be true
      end

      it "handles ?* order (nullable optional string)" do
        result = described_class.from_string("?*string")
        expect(result[:types]).to contain_exactly(String, NilClass)
        expect(result[:optional]).to be true
      end

      it "handles *?integer" do
        result = described_class.from_string("*?integer")
        expect(result[:types]).to contain_exactly(Integer, NilClass)
        expect(result[:optional]).to be true
      end

      it "handles ?*boolean" do
        result = described_class.from_string("?*boolean")
        expect(result[:types]).to contain_exactly(TrueClass, FalseClass, NilClass)
        expect(result[:optional]).to be true
      end

      it "handles *?array" do
        result = described_class.from_string("*?array")
        expect(result[:types]).to contain_exactly(Array, NilClass)
        expect(result[:optional]).to be true
      end

      it "handles *?hash" do
        result = described_class.from_string("*?hash")
        expect(result[:types]).to contain_exactly(Hash, NilClass)
        expect(result[:optional]).to be true
      end

      it "handles *?null without duplicating NilClass" do
        result = described_class.from_string("*?null")
        expect(result[:types]).to contain_exactly(NilClass)
        expect(result[:optional]).to be true
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

      it "raises ArgumentError for optional invalid types" do
        expect { described_class.from_string("*invalid") }
          .to raise_error(ArgumentError, /Unknown type: "invalid"/)
      end

      it "raises ArgumentError for optional nullable invalid types" do
        expect { described_class.from_string("*?invalid") }
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
