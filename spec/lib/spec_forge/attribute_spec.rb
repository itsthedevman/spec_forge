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

      context "and it is a valid variable macro" do
        let(:input) { "variables.var_1" }

        it { is_expected.to be_kind_of(described_class::Variable) }
      end

      context "and it is a valid matcher macro" do
        let(:input) { "matcher.include" }

        it { is_expected.to be_kind_of(described_class::Matcher) }
      end

      context "and it is a valid factory macro" do
        let(:input) { "factories.user" }

        it { is_expected.to be_kind_of(described_class::Factory) }
      end

      context "and it is a valid regex macro" do
        let(:input) { "/test/i" }

        it { is_expected.to be_kind_of(described_class::Regex) }
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

      context "and it is the matcher macro" do
        let(:input) { {"matcher.include": ["foo", "bar"]} }

        it { is_expected.to be_kind_of(described_class::Matcher) }
      end

      context "and it is the factory macro" do
        let(:input) { {"factories.user": {attributes: {}}} }

        it { is_expected.to be_kind_of(described_class::Factory) }
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

  describe "#resolve_as_matcher" do
    let(:matchers) { RSpec::Matchers::BuiltIn }
    let(:attribute) { described_class.from(input) }

    subject(:resolved_matcher) { attribute.resolve_as_matcher }

    context "when the resolved value is ArrayLike" do
      let(:input) do
        [1, "faker.string.random"]
      end

      it "is expected to resolve them into RSpec matchers" do
        expect(resolved_matcher).to be_kind_of(matchers::ContainExactly)
        expect(resolved_matcher.expected).to contain_exactly(
          be_kind_of(matchers::Eq),
          be_kind_of(matchers::Eq)
        )
      end
    end

    context "when the resolved value is HashLike" do
      let(:input) do
        {var_1: 1, var_2: true}
      end

      it "is expected to resolve them into RSpec matchers" do
        expect(resolved_matcher).to be_kind_of(matchers::Include)
        expect(resolved_matcher.expected).to match(
          "var_1" => be_kind_of(matchers::Eq),
          "var_2" => be_kind_of(matchers::Eq)
        )
      end
    end

    context "when the resolved value is an empty ArrayLike" do
      let(:input) { [] }

      it "is expected to resolve into an 'eq' matcher" do
        expect(resolved_matcher).to be_kind_of(matchers::Eq)
        expect(resolved_matcher.expected).to eq([])
      end
    end

    context "when the resolved value is an empty HashLike" do
      let(:input) { {} }

      it "is expected to resolve into an 'eq' matcher" do
        expect(resolved_matcher).to be_kind_of(matchers::Eq)
        expect(resolved_matcher.expected).to eq({})
      end
    end

    context "when the resolved value is Attribute::Matcher" do
      let(:input) { "kind_of.array" }

      it "is expected to return itself" do
        expect(resolved_matcher).to be_kind_of(matchers::BeAKindOf)
      end
    end

    context "when the resolved value is RSpec::Matchers" do
      let(:input) { eq(2) }

      it "is expected to return itself" do
        expect(resolved_matcher).to be_kind_of(matchers::Eq)
      end
    end

    context "when the resolved value is a custom matcher" do
      let(:input) { forge_and(eq(1)) }

      it "is expected to return itself" do
        expect(resolved_matcher).to be_kind_of(RSpec::Matchers::DSL::Matcher)
      end
    end

    context "when the resolved value is regex" do
      let(:input) { "/test/" }

      it "is expected to resolve into Match" do
        expect(resolved_matcher).to be_kind_of(matchers::Match)
        expect(resolved_matcher.expected).to be_kind_of(Regexp)
      end
    end

    context "when the resolved value is anything else" do
      let(:input) { "faker.string.random.object_id" }

      it "is expected to resolve into Eq" do
        expect(resolved_matcher).to be_kind_of(matchers::Eq)
        expect(resolved_matcher.expected).to be_kind_of(Integer)
      end
    end
  end
end
