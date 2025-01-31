# frozen_string_literal: true

RSpec.describe SpecForge::Attribute::Matcher do
  let(:input) { "" }
  let(:positional) { [] }
  let(:keyword) { {} }

  subject(:attribute) { described_class.new(input, positional, keyword) }

  describe "KEYWORD_REGEX" do
    subject(:regex) { described_class::KEYWORD_REGEX }

    context "when the input starts with 'matcher'" do
      let(:input) { "matcher.include" }

      it { expect(input).to match(regex) }
    end

    context "when the input starts with 'be'" do
      let(:input) { "be.nil" }

      it { expect(input).to match(regex) }
    end

    context "when the input starts with 'kind_of'" do
      let(:input) { "kind_of.integer" }

      it { expect(input).to match(regex) }
    end
  end

  describe "#initialize" do
    context "when the input starts with 'matcher'" do
      context "and the matcher does not exist" do
        let(:input) { "matcher.does_not_exist" }

        it do
          expect { attribute }.to raise_error(NameError)
        end
      end

      context "and the matcher exists" do
        let(:input) { "matcher.contain_exactly" }
        let(:positional) { [1] }

        it "is expected to find the matcher" do
          expect(attribute.matcher_method).to be_kind_of(UnboundMethod)
          expect(attribute.matcher_method.name).to eq(:contain_exactly)
          expect(attribute.arguments[:positional]).to eq([1])
        end

        it "is expected to work with RSpec" do
          expect([1]).to(attribute.value)
        end
      end
    end

    context "when the starts with 'kind_of'" do
      context "and the matcher does not exist" do
        let(:input) { "kind_of.does_not_exist" }

        it do
          expect { attribute }.to raise_error(NameError)
        end
      end

      context "and the matcher exists" do
        let(:input) { "kind_of.string" }

        it "is expected to find the matcher" do
          expect(attribute.matcher_method).to be_kind_of(UnboundMethod)
          expect(attribute.matcher_method.name).to eq(:be_kind_of)
          expect(attribute.arguments[:positional]).to eq([String])
        end

        it "is expected to work with RSpec" do
          expect("").to(attribute.value)
        end
      end
    end

    context "when the starts with 'be'" do
      context "and the matcher does not exist" do
        let(:input) { "be.does_not_exist" }

        it "is expected to return a BePredicate" do
          expect(attribute.matcher_method).to be_kind_of(UnboundMethod)
          expect(attribute.arguments[:positional]).to eq([:be_does_not_exist])

          predicate = attribute.value
          expect(predicate).to be_kind_of(RSpec::Matchers::BuiltIn::BePredicate)
          expect(predicate.instance_variable_get(:@method_name)).to eq(:be_does_not_exist)
        end

        it "is expected to NOT work with RSpec" do
          expect { expect("").to(attribute.value) }.to raise_error(
            "expected \"\" to respond to `does_not_exist?`"
          )
        end
      end

      context "and the matcher is predefined" do
        let(:input) { "be.truthy" }

        it "is expected to find the matcher" do
          expect(attribute.matcher_method).to be_kind_of(UnboundMethod)
          expect(attribute.matcher_method.name).to eq(:be_truthy)
          expect(attribute.arguments[:positional]).to eq([])
        end

        it "is expected to work with RSpec" do
          expect("hello!").to(attribute.value)
        end
      end

      context "and the matcher is dynamic" do
        let(:input) { "be.empty" }

        it "is expected to find the matcher" do
          expect(attribute.matcher_method).to be_kind_of(UnboundMethod)
          expect(attribute.arguments[:positional]).to eq([:be_empty])

          predicate = attribute.value
          expect(predicate).to be_kind_of(RSpec::Matchers::BuiltIn::BePredicate)
          expect(predicate.instance_variable_get(:@method_name)).to eq(:be_empty)
        end

        it "is expected to work with RSpec" do
          expect([]).to(attribute.value)
        end
      end

      context "and the matcher is 'nil'" do
        let(:input) { "be.nil" }

        it "is expected to find the matcher" do
          expect(attribute.matcher_method).to be_kind_of(UnboundMethod)
          expect(attribute.matcher_method.name).to eq(:be)
          expect(attribute.arguments[:positional]).to eq([nil])
        end

        it "is expected to work with RSpec" do
          expect(nil).to(attribute.value)
        end
      end

      context "and the matcher is 'true'" do
        let(:input) { "be.true" }

        it "is expected to find the matcher" do
          expect(attribute.matcher_method).to be_kind_of(UnboundMethod)
          expect(attribute.matcher_method.name).to eq(:be)
          expect(attribute.arguments[:positional]).to eq([true])
        end

        it "is expected to work with RSpec" do
          expect(true).to(attribute.value)
        end
      end

      context "and the matcher is 'false'" do
        let(:input) { "be.false" }

        it "is expected to find the matcher" do
          expect(attribute.matcher_method).to be_kind_of(UnboundMethod)
          expect(attribute.matcher_method.name).to eq(:be)
          expect(attribute.arguments[:positional]).to eq([false])
        end

        it "is expected to work with RSpec" do
          expect(false).to(attribute.value)
        end
      end

      context "and the matcher is 'greater_than'" do
        let(:input) { "be.greater_than" }
        let(:positional) { [1] }

        it "is expected to find the matcher" do
          expect(attribute.matcher_method).to be_kind_of(UnboundMethod)
          expect(attribute.matcher_method.name).to eq(:>)
          expect(attribute.arguments[:positional]).to eq([1])
        end

        it "is expected to work with RSpec" do
          expect(2).to(attribute.value)
        end
      end

      context "and the matcher is 'greater_than_or_equal'" do
        let(:input) { "be.greater_than_or_equal" }
        let(:positional) { [1] }

        it "is expected to find the matcher" do
          expect(attribute.matcher_method).to be_kind_of(UnboundMethod)
          expect(attribute.matcher_method.name).to eq(:>=)
          expect(attribute.arguments[:positional]).to eq([1])
        end

        it "is expected to work with RSpec" do
          expect(1).to(attribute.value)
        end
      end

      context "and the matcher is 'greater'" do
        let(:input) { "be.greater" }
        let(:positional) { [1] }

        it "is expected to find the matcher" do
          expect(attribute.matcher_method).to be_kind_of(UnboundMethod)
          expect(attribute.matcher_method.name).to eq(:>)
          expect(attribute.arguments[:positional]).to eq([1])
        end

        it "is expected to work with RSpec" do
          expect(2).to(attribute.value)
        end
      end

      context "and the matcher is 'greater_or_equal'" do
        let(:input) { "be.greater_or_equal" }
        let(:positional) { [1] }

        it "is expected to find the matcher" do
          expect(attribute.matcher_method).to be_kind_of(UnboundMethod)
          expect(attribute.matcher_method.name).to eq(:>=)
          expect(attribute.arguments[:positional]).to eq([1])
        end

        it "is expected to work with RSpec" do
          expect(1).to(attribute.value)
        end
      end

      context "and the matcher is 'less_than'" do
        let(:input) { "be.less_than" }
        let(:positional) { [1] }

        it "is expected to find the matcher" do
          expect(attribute.matcher_method).to be_kind_of(UnboundMethod)
          expect(attribute.matcher_method.name).to eq(:<)
          expect(attribute.arguments[:positional]).to eq([1])
        end

        it "is expected to work with RSpec" do
          expect(0).to(attribute.value)
        end
      end

      context "and the matcher is 'less_than_or_equal'" do
        let(:input) { "be.less_than_or_equal" }
        let(:positional) { [1] }

        it "is expected to find the matcher" do
          expect(attribute.matcher_method).to be_kind_of(UnboundMethod)
          expect(attribute.matcher_method.name).to eq(:<=)
          expect(attribute.arguments[:positional]).to eq([1])
        end

        it "is expected to work with RSpec" do
          expect(1).to(attribute.value)
        end
      end

      context "and the matcher is 'less'" do
        let(:input) { "be.less" }
        let(:positional) { [1] }

        it "is expected to find the matcher" do
          expect(attribute.matcher_method).to be_kind_of(UnboundMethod)
          expect(attribute.matcher_method.name).to eq(:<)
          expect(attribute.arguments[:positional]).to eq([1])
        end

        it "is expected to work with RSpec" do
          expect(0).to(attribute.value)
        end
      end

      context "and the matcher is 'less_or_equal'" do
        let(:input) { "be.less_or_equal" }
        let(:positional) { [1] }

        it "is expected to find the matcher" do
          expect(attribute.matcher_method).to be_kind_of(UnboundMethod)
          expect(attribute.matcher_method.name).to eq(:<=)
          expect(attribute.arguments[:positional]).to eq([1])
        end

        it "is expected to work with RSpec" do
          expect(1).to(attribute.value)
        end
      end
    end
  end
end
