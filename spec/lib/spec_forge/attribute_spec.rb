# frozen_string_literal: true

RSpec.describe SpecForge::Attribute do
  describe ".from" do
    let(:input) {}

    subject(:attribute) { described_class.from(input) }

    context "when the input is an Attribute" do
      let(:input) { described_class::Literal.new(1) }

      it "is expected to return the value without any modifications" do
        expect(attribute).to eq(input)
        expect(attribute).to eql(input)
      end
    end

    context "when the input is a String" do
      context "and it is a valid faker macro" do
        let(:input) { "faker.number.positive" }

        it { is_expected.to be_kind_of(described_class::Faker) }
      end

      context "and it is a valid faker macro, but in mixed caps" do
        let(:input) { "FAkEr.nUMBEr.positIVe" }

        it { is_expected.to be_kind_of(described_class::Faker) }
      end

      context "and it is a misspelled faker macro" do
        let(:input) { "fakeer.number.positive" }

        it { is_expected.to be_kind_of(described_class::Literal) }
      end

      context "and it is literally anything else" do
        let(:input) { "literally anything else" }

        it { is_expected.to be_kind_of(described_class::Literal) }
      end
    end

    context "when the input is a Boolean" do
      let(:input) { true }

      it { is_expected.to be_kind_of(described_class::Literal) }
    end

    context "when the input is a Hash" do
      context "and it is the faker macro" do
        let(:input) { {"faker.number.between": {from: 0, to: 10}} }

        it { is_expected.to be_kind_of(described_class::Faker) }
      end

      context "and it is the transform macro" do
        let(:input) { {"transform.join": ["foo", "bar"]} }

        it { is_expected.to be_kind_of(described_class::Transform) }
      end

      context "and it is not an expanded macro" do
        let(:input) { {foo: "foo", bar: "bar"} }

        it { is_expected.to be_kind_of(described_class::ResolvableHash) }
      end

      context "and it has nested attributes" do
        let(:input) do
          {
            key_1: {
              key_2: {
                key_3: "faker.number.positive"
              }
            }
          }
        end

        it "is expected to deeply convert hash values to attributes" do
          expect(attribute).to be_kind_of(described_class::ResolvableHash)

          # Lol
          nested_attribute = attribute.value[:key_1].value[:key_2].value[:key_3]
          expect(nested_attribute).to be_kind_of(described_class::Faker)
        end
      end
    end

    context "when the input is an Array" do
      context "and it is simple" do
        let(:input) { [] }

        it { is_expected.to be_kind_of(described_class::ResolvableArray) }
      end

      context "and it contains nested attributes" do
        let(:input) do
          [
            "faker.number.positive",
            [
              "faker.number.positive",
              {
                key_1: {
                  "transform.join" => [
                    "foo", " ", "bar"
                  ]
                }
              }
            ]
          ]
        end

        it "is expected to deeply convert" do
          expect(attribute).to be_kind_of(described_class::ResolvableArray)

          expect(attribute.value.first).to be_kind_of(described_class::Faker)

          array = attribute.value.second.value
          expect(array.first).to be_kind_of(described_class::Faker)

          hash_value = array.second.value[:key_1]
          expect(hash_value).to be_kind_of(described_class::Transform)
        end
      end
    end
  end

  describe "#value" do
    subject(:value) { described_class.new("").value }

    context "when the method has not been redefined" do
      it "is expected to raise" do
        expect { value }.to raise_error("not implemented")
      end
    end
  end

  describe "#resolve" do
    let(:input) do
      [
        "faker.number.positive",
        [
          "faker.number.positive",
          Faker::String.random, # Literal
          Faker::Number.positive, # Literal
          {
            key_1: {
              "transform.join" => [
                "foo", " ", "bar"
              ]
            }
          }
        ]
      ]
    end

    subject(:resolved) { described_class.from(input).resolve }

    it "recursively converts the attributes and returns the result" do
      expect(resolved).to match([
        be_kind_of(Numeric),
        [
          be_kind_of(Numeric),
          be_kind_of(String),
          be_kind_of(Numeric),
          {
            key_1: "foo bar"
          }
        ]
      ])
    end
  end

  describe "#to_proc" do
    let(:attribute) { described_class.new("") }

    subject(:proc) { attribute.to_proc }

    it { is_expected.to be_kind_of(Proc) }

    context "when #value has not been redefined" do
      it "is expected to raise when called" do
        expect { proc.call }.to raise_error("not implemented")
      end
    end

    context "when #value has been redefined" do
      before do
        allow(attribute).to receive(:value).and_return(12345)
      end

      it "is expected to return the value when called" do
        expect(proc.call).to eq(12345)
      end
    end
  end

  describe "#==" do
    let(:other) {}
    let(:attribute) { described_class::Literal.new(12345) }

    subject(:equals) { attribute == other }

    context "when the other is an Attribute" do
      let(:other) { described_class::Literal.new(12345) }

      it { is_expected.to be(true) }
    end

    context "when the other is not an Attribute" do
      context "and is not equal to the input" do
        let(:other) { "hello world!" }

        it { is_expected.to be(false) }
      end

      context "and is equal to the input" do
        let(:other) { 12345 }

        it { is_expected.to be(true) }
      end
    end
  end
end
