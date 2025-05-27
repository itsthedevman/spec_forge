# frozen_string_literal: true

RSpec.describe SpecForge::Documentation::OpenAPI::V3_0::Schema do
  describe "converting type to schema hash" do
    let(:type) {}

    subject(:schema) { described_class.new(type:).type }

    context "when the type is 'datetime'" do
      let(:type) { "datetime" }

      it "is expected to return a schema with type 'string' and format 'date-time'" do
        is_expected.to eq({type: "string", format: "date-time"})
      end
    end

    context "when the type is 'time'" do
      let(:type) { "time" }

      it "is expected to return a schema with type 'string' and format 'date-time'" do
        is_expected.to eq({type: "string", format: "date-time"})
      end
    end

    context "when the type is 'int64'" do
      let(:type) { "int64" }

      it "is expected to return a schema with type 'integer' and format 'int64'" do
        is_expected.to eq({type: "integer", format: "int64"})
      end
    end

    context "when the type is 'i64'" do
      let(:type) { "i64" }

      it "is expected to return a schema with type 'integer' and format 'int64'" do
        is_expected.to eq({type: "integer", format: "int64"})
      end
    end

    context "when the type is 'int32'" do
      let(:type) { "int32" }

      it "is expected to return a schema with type 'integer' and format 'int32'" do
        is_expected.to eq({type: "integer", format: "int32"})
      end
    end

    context "when the type is 'i32'" do
      let(:type) { "i32" }

      it "is expected to return a schema with type 'integer' and format 'int32'" do
        is_expected.to eq({type: "integer", format: "int32"})
      end
    end

    context "when the type is 'double'" do
      let(:type) { "double" }

      it "is expected to return a schema with type 'number' and format 'double'" do
        is_expected.to eq({type: "number", format: "double"})
      end
    end

    context "when the type is 'float'" do
      let(:type) { "float" }

      it "is expected to return a schema with type 'number' and format 'float'" do
        is_expected.to eq({type: "number", format: "float"})
      end
    end

    context "when the type is 'boolean'" do
      let(:type) { "boolean" }

      it "is expected to return a schema with type 'boolean'" do
        is_expected.to eq({type:})
      end
    end

    context "when the type is 'number'" do
      let(:type) { "number" }

      it "is expected to return a schema with type 'number'" do
        is_expected.to eq({type:})
      end
    end

    context "when the type is 'integer'" do
      let(:type) { "integer" }

      it "is expected to return a schema with type 'integer'" do
        is_expected.to eq({type:})
      end
    end

    context "when the type is 'string'" do
      let(:type) { "string" }

      it "is expected to return a schema with type 'string'" do
        is_expected.to eq({type:})
      end
    end

    context "when the type is 'array'" do
      let(:type) { "array" }

      it "is expected to return a schema with type 'array'" do
        is_expected.to eq({type: "array"})
      end
    end

    context "when the type is 'object'" do
      let(:type) { "object" }

      it "is expected to return a schema with type 'object'" do
        is_expected.to eq({type: "object"})
      end
    end

    context "when the type is anything else" do
      let(:type) { "password" }

      it "is expected to return a schema with type 'string' and the format as the type" do
        is_expected.to eq({type: "string", format: type})
      end
    end
  end
end
