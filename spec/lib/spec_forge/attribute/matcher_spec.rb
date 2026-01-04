# frozen_string_literal: true

RSpec.describe SpecForge::Attribute::Matcher do
  let(:input) { "" }
  let(:positional) { [] }
  let(:keyword) { {} }

  subject(:attribute) { described_class.new(input, positional, keyword) }

  include_examples "from_input_to_attribute" do
    let(:input) { "kind_of.string" }
  end

  include_examples "from_input_to_attribute" do
    let(:input) { "be.nil" }
  end

  include_examples "from_input_to_attribute" do
    let(:input) { "matcher.include" }
  end

  include_examples "from_input_to_attribute" do
    let(:input) { "matchers.all" }
  end

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
          expect { attribute }.to raise_error(SpecForge::Error::UndefinedMatcherError) do |e|
            expect(e.message).to match(
              "Undefined matcher method \"does_not_exist\" is not available"
            )
          end
        end
      end

      context "and the matcher exists" do
        let(:input) { "matcher.contain_exactly" }
        let(:positional) { [1] }

        it "is expected to find the matcher" do
          expect(attribute.matcher_method).to be_kind_of(Method)
          expect(attribute.matcher_method.name).to eq(:contain_exactly)
          expect(attribute.arguments[:positional]).to eq([1])
        end

        it "is expected to work with RSpec" do
          expect([1]).to(attribute.value)
        end
      end

      context "and the matcher method is 'and'" do
        let(:input) { "matcher.and" }
        let(:positional) { ["kind_of.string"] }

        it "is expected to use 'forge_and' matcher" do
          expect(attribute.matcher_method).to be_kind_of(Method)
          expect(attribute.matcher_method.name).to eq(:forge_and)
          expect(attribute.arguments[:positional]).to contain_exactly(
            be_kind_of(SpecForge::Attribute)
          )
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
          expect(attribute.matcher_method).to be_kind_of(Method)
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
          expect(attribute.matcher_method).to be_kind_of(Method)
          expect(attribute.matcher_method.name).to eq(:be_does_not_exist)
          expect(attribute.arguments[:positional]).to eq([])
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
          expect(attribute.matcher_method).to be_kind_of(Method)
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
          expect(attribute.matcher_method).to be_kind_of(Method)
          expect(attribute.matcher_method.name).to eq(:be_empty)
          expect(attribute.arguments[:positional]).to eq([])
        end

        it "is expected to work with RSpec" do
          expect([]).to(attribute.value)
        end
      end

      context "and the matcher is 'nil'" do
        let(:input) { "be.nil" }

        it "is expected to find the matcher" do
          expect(attribute.matcher_method).to be_kind_of(Method)
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
          expect(attribute.matcher_method).to be_kind_of(Method)
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
          expect(attribute.matcher_method).to be_kind_of(Method)
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
          expect(attribute.matcher_method).to be_kind_of(Method)
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
          expect(attribute.matcher_method).to be_kind_of(Method)
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
          expect(attribute.matcher_method).to be_kind_of(Method)
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
          expect(attribute.matcher_method).to be_kind_of(Method)
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
          expect(attribute.matcher_method).to be_kind_of(Method)
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
          expect(attribute.matcher_method).to be_kind_of(Method)
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
          expect(attribute.matcher_method).to be_kind_of(Method)
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
          expect(attribute.matcher_method).to be_kind_of(Method)
          expect(attribute.matcher_method.name).to eq(:<=)
          expect(attribute.arguments[:positional]).to eq([1])
        end

        it "is expected to work with RSpec" do
          expect(1).to(attribute.value)
        end
      end
    end

    context "when a matcher has a matcher as an argument" do
      let(:input) { "matcher.include" }
      let(:keyword) do
        {
          "matcher.include" => {
            "matcher.include" => {foo: "bar"}
          }
        }
      end

      it "is expected to move them to the positional arguments" do
        expect(attribute.arguments[:keyword]).to be_empty
        expect(attribute.arguments[:positional].size).to eq(1)

        matcher = attribute.arguments[:positional].first
        expect(matcher).to be_kind_of(SpecForge::Attribute::Matcher)
        expect(matcher.arguments[:keyword]).to be_empty
        expect(matcher.arguments[:positional].size).to eq(1)

        # Nesting works, excellent
        matcher = matcher.arguments[:positional].first
        expect(matcher).to be_kind_of(SpecForge::Attribute::Matcher)
      end
    end
  end

  context "when 'matcher.match' is provided keyword arguments" do
    let(:input) { "matcher.match" }
    let(:keyword) { {foo: "bar"} }

    it do
      resolved = attribute.resolved
      expect(resolved).to be_kind_of(RSpec::Matchers::BuiltIn::Match)
      expect(resolved.expected).to eq("foo" => "bar")
    end
  end

  context "when 'matcher.match' is provided positional arguments" do
    let(:input) { "matcher.match" }
    let(:positional) { ["foo"] }

    it do
      resolved = attribute.resolved
      expect(resolved).to be_kind_of(RSpec::Matchers::BuiltIn::Match)
      expect(resolved.expected).to eq("foo")
    end
  end

  describe "#resolve_as_matcher" do
    let(:matchers) { RSpec::Matchers::BuiltIn }

    subject(:resolved_matcher) { attribute.resolve_as_matcher }

    context "when the method is include and the argument is a string" do
      let(:input) { "matcher.include" }
      let(:positional) { ["foo"] }

      it "is expected to not convert the string to a matcher" do
        expect(resolved_matcher).to be_kind_of(matchers::Include)
        expect(resolved_matcher.expected).to eq(["foo"])
      end
    end

    context "when the method is include and the argument is a regex" do
      let(:input) { "matcher.include" }
      let(:positional) { ["/foo/"] }

      it "is expected to convert the regex to a match matcher" do
        expect(resolved_matcher).to be_kind_of(matchers::Include)
        expect(resolved_matcher.expected.first).to be_kind_of(matchers::Match)
        expect(resolved_matcher.expected.first.expected).to eq(/foo/)
      end
    end

    context "when the method is start_with and the argument is a string" do
      let(:input) { "matcher.start_with" }
      let(:positional) { ["foo"] }

      it "is expected to not convert the string to a matcher" do
        expect(resolved_matcher).to be_kind_of(matchers::StartWith)
        expect(resolved_matcher.expected).to eq("foo")
      end
    end

    context "when the method is start_with and the argument is a string" do
      let(:input) { "matcher.have_size" }
      let(:positional) { [5] }

      it "is expected to not convert the integer to a matcher" do
        expect(resolved_matcher).to be_kind_of(RSpec::Matchers::DSL::Matcher)
        expect(resolved_matcher.expected).to be_kind_of(RSpec::Matchers::BuiltIn::Eq)
        expect(resolved_matcher.expected.expected).to eq(5)
      end
    end

    context "when the method is all and the argument is a regex" do
      let(:input) { "matcher.all" }
      let(:positional) { ["/foo/"] }

      it "is expected to convert the regex to a match matcher" do
        expect(resolved_matcher).to be_kind_of(matchers::All)
        expect(resolved_matcher.matcher).to be_kind_of(matchers::Match)
        expect(resolved_matcher.matcher.expected).to eq(/foo/)
      end
    end

    context "when the method is matcher 'and'" do
      let(:input) { "matcher.and" }
      let(:positional) { ["kind_of.string", "/foo/", "bar"] }

      it "is expected to convert the appropriate arguments to matchers" do
        matchers_array = resolved_matcher.expected

        expect(matchers_array[0]).to be_kind_of(matchers::BeAKindOf)

        expect(matchers_array[1]).to be_kind_of(matchers::Match)
        expect(matchers_array[1].expected).to eq(/foo/)

        expect(matchers_array[2]).to be_kind_of(matchers::Eq)
        expect(matchers_array[2].expected).to eq("bar")
      end
    end

    context "when the matcher has nested structure" do
      let(:input) { "matcher.all" }

      let(:positional) do
        [
          {"matcher.include" => ["/foo/", "bar"]}
        ]
      end

      it "is expected to convert the nested structure" do
        expect(resolved_matcher).to be_kind_of(matchers::All)

        inner_matcher = resolved_matcher.matcher
        expect(inner_matcher).to be_kind_of(matchers::Include)

        expect(inner_matcher.expected[0]).to be_kind_of(matchers::Match)
        expect(inner_matcher.expected[0].expected).to eq(/foo/)

        expect(inner_matcher.expected[1]).to eq("bar")
      end
    end

    context "when the method is include and the argument is an array" do
      let(:input) { "matcher.include" }
      let(:positional) { [[1, 2, 3]] }

      it "is expected to convert the array" do
        expect(resolved_matcher).to be_kind_of(matchers::Include)
        expect(resolved_matcher.expected.first).to be_kind_of(Array)
      end
    end

    context "when the method is include and the argument is a hash" do
      let(:input) { "matcher.include" }
      let(:positional) { [{key: "value"}] }

      it "is expected to convert the hash" do
        expect(resolved_matcher).to be_kind_of(matchers::Include)
        expect(resolved_matcher.expected.first).to be_kind_of(Array)
      end
    end

    context "when the argument is a deeply nested structure" do
      let(:input) { "matcher.all" }
      let(:positional) do
        [
          {
            "matcher.include" => {
              id: "kind_of.integer",
              name: "kind_of.string",
              email: {
                "matcher.and" => [
                  "kind_of.string",
                  "/@/",
                  {"matcher.include" => "."}
                ]
              },
              created_at: "kind_of.string"
            }
          }
        ]
      end

      it "is expected to convert the nested structure" do
        expect(resolved_matcher).to be_kind_of(matchers::All)

        include_matcher = resolved_matcher.matcher
        expect(include_matcher).to be_kind_of(matchers::Include)

        hash_arg = include_matcher.expected

        expect(hash_arg["id"]).to be_kind_of(matchers::BeAKindOf)
        expect(hash_arg["id"].expected).to eq(Integer)

        expect(hash_arg["name"]).to be_kind_of(matchers::BeAKindOf)
        expect(hash_arg["name"].expected).to eq(String)

        expect(hash_arg["created_at"]).to be_kind_of(matchers::BeAKindOf)
        expect(hash_arg["created_at"].expected).to eq(String)

        and_matcher = hash_arg["email"]
        expect(and_matcher).to be_kind_of(RSpec::Matchers::DSL::Matcher)

        and_matchers = and_matcher.expected

        expect(and_matchers[0]).to be_kind_of(matchers::BeAKindOf)
        expect(and_matchers[0].expected).to eq(String)

        expect(and_matchers[1]).to be_kind_of(matchers::Match)
        expect(and_matchers[1].expected).to eq(/@/)

        expect(and_matchers[2]).to be_kind_of(matchers::Include)
        expect(and_matchers[2].expected).to eq(include(".").expected)
      end
    end
  end
end
