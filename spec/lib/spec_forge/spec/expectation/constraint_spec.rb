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
        SpecForge.context.global.set(variables: {status: 404})
      end

      it "is expected to store the status as an integer" do
        expect(constraint.status).to be_kind_of(SpecForge::Attribute::Global)
        expect(constraint.status.resolved).to eq(404)
      end
    end
  end

  describe "#as_matchers" do
    let(:matchers) { RSpec::Matchers::BuiltIn }

    subject(:resolved_matchers) { constraint.as_matchers }

    context "when 'status' is resolved" do
      let(:status) { 420 }

      subject(:resolved_status) { resolved_matchers[:status] }

      it "is expected to be converted to a matcher" do
        is_expected.to be_kind_of(matchers::Eq)
        is_expected.to have_attributes(expected: status)
      end
    end

    context "when 'json' is a hash" do
      let(:json) do
        {
          string: "hello world",
          integer: 1,
          bool: false,
          matcher: {"matcher.include" => [1]},
          faker: "faker.string.random"
        }
      end

      subject(:resolved_json) { resolved_matchers[:json] }

      it "is expected to stringify all hash keys, and convert the values to matchers. Leaving the root hash as a Hash" do
        expect(resolved_json).to be_kind_of(Hash)

        expect(resolved_json["string"]).to be_kind_of(matchers::Eq)
        expect(resolved_json["string"]).to have_attributes(expected: "hello world")

        expect(resolved_json["integer"]).to be_kind_of(matchers::Eq)
        expect(resolved_json["integer"]).to have_attributes(expected: 1)

        expect(resolved_json["bool"]).to be_kind_of(matchers::Eq)
        expect(resolved_json["bool"]).to have_attributes(expected: false)

        expect(resolved_json["matcher"]).to be_kind_of(matchers::Include)
        expect(resolved_json["matcher"]).to have_attributes(expected: [1])

        expect(resolved_json["faker"]).to be_kind_of(matchers::Eq)
        expect(resolved_json["faker"]).to have_attributes(expected: be_kind_of(String))
      end
    end

    context "when 'json' is an array" do
      let(:json) do
        [
          [1.0, {var: 1}],
          {var: true},
          "/testing/"
        ]
      end

      subject(:resolved_json) { resolved_matchers[:json] }

      it "is expected to convert to a matcher" do
        expect(resolved_json).to be_kind_of(matchers::ContainExactly)

        expected = resolved_json.expected

        # Index 0 (Array)
        matcher = expected[0]
        expect(matcher).to be_kind_of(matchers::ContainExactly)

        inner = matcher.expected
        expect(inner[0]).to be_kind_of(matchers::Eq)
        expect(inner[0]).to have_attributes(expected: 1)

        expect(inner[1]).to be_kind_of(matchers::Include)
        expect(inner[1]).to have_attributes(expected: {
          "var" => be_kind_of(matchers::Eq).and(have_attributes(expected: 1))
        })

        # Index 1 (Hash)
        matcher = expected[1]
        expect(matcher).to be_kind_of(matchers::Include)

        inner = matcher.expected
        expect(inner["var"]).to be_kind_of(matchers::Eq)
        expect(inner["var"]).to have_attributes(expected: true)

        # Index 2 (Regex)
        matcher = expected[2]
        expect(matcher).to be_kind_of(matchers::Match)

        expect(matcher.expected).to eq(/testing/)
      end
    end
  end
end
