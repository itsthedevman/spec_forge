# frozen_string_literal: true

RSpec.describe SpecForge::Spec::Expectation::Constraint do
  let(:status) { 404 }
  let(:json) { {} }

  subject(:constraint) do
    described_class.new(
      status: SpecForge::Attribute.from(status),
      json: SpecForge::Attribute.from(json)
    )
  end

  describe "#initialize" do
    context "when 'status' is an Integer" do
      let(:status) { 404 }

      it "is expected to store the status as an integer" do
        expect(constraint.status).to eq(404)
        expect(constraint.status).to be_kind_of(SpecForge::Attribute::Literal)
      end
    end

    context "when 'status' is resolvable as an attribute" do
      let(:status) { "global.variables.status" }

      before do
        SpecForge.context.global.update(variables: {status: 404})
      end

      it "is expected to store the status as an integer" do
        expect(constraint.status).to be_kind_of(SpecForge::Attribute::Global)
        expect(constraint.status.resolve).to eq(404)
      end
    end

    context "when 'json' is provided" do
      context "and the 'json' is a hash" do
        let(:json) { {foo: "faker.string.random"} }

        it "is expected to convert to a matcher" do
          expect(constraint.json).to be_kind_of(SpecForge::Attribute::Matcher)
          expect(constraint.json.input).to eq("matcher.include")
          expect(constraint.json.arguments[:keyword][:foo]).to be_kind_of(
            SpecForge::Attribute::Faker
          )
        end

        context "and it has matchers" do
          let(:json) do
            {foo: "/testing/i", bar: "bar", baz: SpecForge::Attribute.from("kind_of.string")}
          end

          it "is expected to convert the json attributes to matchers" do
            arguments = constraint.json.arguments[:keyword]

            expect(arguments[:foo].resolve).to be_kind_of(RSpec::Matchers::BuiltIn::Match)
            expect(arguments[:bar].resolve).to be_kind_of(RSpec::Matchers::BuiltIn::Eq)
            expect(arguments[:baz].resolve).to be_kind_of(RSpec::Matchers::BuiltIn::BeAKindOf)
          end
        end
      end

      context "and the 'json' is an array" do
        let(:json) { ["faker.string.random"] }

        it "is expected to convert to a matcher" do
          expect(constraint.json).to be_kind_of(SpecForge::Attribute::Matcher)
          expect(constraint.json.input).to eq("matcher.contain_exactly")
          expect(constraint.json.arguments[:positional].first).to be_kind_of(
            SpecForge::Attribute::Faker
          )
        end

        context "and it has matcher" do
          let(:json) { ["bar", [1], {foo: SpecForge::Attribute.from("faker.string.random")}] }

          it "is expected to convert the array values to matchers" do
            arguments = constraint.json.arguments[:positional]

            expect(arguments.first.resolve).to be_kind_of(RSpec::Matchers::BuiltIn::Eq)

            array_arg = arguments.second.resolve
            expect(array_arg).to be_kind_of(RSpec::Matchers::BuiltIn::ContainExactly)
            expect(array_arg.expected).to contain_exactly(
              be_kind_of(RSpec::Matchers::BuiltIn::Eq)
            )

            hash_arg = arguments.third
            expect(hash_arg).to be_kind_of(SpecForge::Attribute::Matcher)
            expect(hash_arg.input).to eq("matcher.include")

            expect(hash_arg.arguments[:keyword][:foo]).to be_kind_of(
              SpecForge::Attribute::Faker
            )
          end
        end
      end

      context "and the 'json' is blank" do
        let(:json) { {} }

        it "sets the json value to resolve to nil" do
          expect(constraint.json.resolve).to be(nil)
        end
      end
    end
  end
end
