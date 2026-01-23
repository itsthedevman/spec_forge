# frozen_string_literal: true

RSpec.describe SpecForge::Attribute::Generate do
  subject(:attribute) { described_class.new(input, [], keyword) }

  let(:input) { "generate.array" }
  let(:keyword) { {} }

  describe "KEYWORD_REGEX" do
    subject(:regex) { described_class::KEYWORD_REGEX }

    it "matches 'generate.' prefix" do
      expect("generate.array").to match(regex)
    end

    it "matches case insensitively" do
      expect("GENERATE.array").to match(regex)
      expect("Generate.Array").to match(regex)
    end

    it "does not match without the prefix" do
      expect("array").not_to match(regex)
      expect("gen.array").not_to match(regex)
    end
  end

  describe "Attribute.from" do
    subject(:attribute) { SpecForge::Attribute.from(hash) }

    context "with size and value" do
      let(:hash) { {"generate.array" => {size: 3, value: "test"}} }

      it "creates a Generate attribute" do
        expect(attribute).to be_a(described_class)
        expect(attribute.function).to eq("array")
      end
    end

    context "with size and value containing index template" do
      let(:hash) { {"generate.array" => {size: 5, value: "item_{{ index }}"}} }

      it "creates a Generate attribute" do
        expect(attribute).to be_a(described_class)
        expect(attribute.function).to eq("array")
      end
    end
  end

  describe "#initialize" do
    let(:keyword) { {size: 3, value: "test"} }

    it "extracts the function name" do
      expect(attribute.function).to eq("array")
    end

    context "with invalid function" do
      let(:input) { "generate.invalid" }

      it "raises an error" do
        expect { attribute }.to raise_error(SpecForge::Error)
      end
    end
  end

  describe "#value" do
    # Helper to execute with a forge context
    def with_context(vars = {}, &block)
      context = SpecForge::Forge::Context.new(
        variables: SpecForge::Forge::Variables.new(static: vars)
      )

      SpecForge::Forge.with_context(context, &block)
    end

    context "with static value" do
      let(:keyword) { {size: 3, value: "static"} }

      it "generates an array of the specified size" do
        result = with_context { attribute.value }

        expect(result).to be_an(Array)
        expect(result.size).to eq(3)
        expect(result).to all(eq("static"))
      end
    end

    context "with faker value" do
      let(:keyword) { {size: 5, value: "{{ faker.number.positive }}"} }

      it "generates an array with evaluated values" do
        result = with_context { attribute.value }

        expect(result).to be_an(Array)
        expect(result.size).to eq(5)
        expect(result).to all(be_a(Numeric))
      end
    end

    context "with index template" do
      let(:keyword) { {size: 3, value: "user_{{ index }}"} }

      it "generates an array with index-interpolated values" do
        result = with_context { attribute.value }

        expect(result).to be_an(Array)
        expect(result.size).to eq(3)
        expect(result).to eq(["user_0", "user_1", "user_2"])
      end
    end

    context "with faker and index combined" do
      let(:keyword) { {size: 3, value: "{{ faker.internet.username }}_{{ index }}"} }

      it "generates an array with faker values and index" do
        result = with_context { attribute.value }

        expect(result).to be_an(Array)
        expect(result.size).to eq(3)
        expect(result[0]).to match(/.+_0$/)
        expect(result[1]).to match(/.+_1$/)
        expect(result[2]).to match(/.+_2$/)
      end
    end

    context "with other variables and index" do
      let(:keyword) { {size: 2, value: "{{ prefix }}_{{ index }}"} }

      it "generates an array with variables and index" do
        result = with_context(prefix: "item") { attribute.value }

        expect(result).to eq(["item_0", "item_1"])
      end
    end

    context "when index shadows a stored variable" do
      let(:keyword) { {size: 2, value: "{{ index }}"} }

      it "uses the generation index, not the stored variable" do
        result = with_context(index: "should_be_shadowed") { attribute.value }

        # Returns integers since {{ index }} is the entire template value
        expect(result).to eq([0, 1])
      end
    end

    context "with size of 0" do
      let(:keyword) { {size: 0, value: "test"} }

      it "returns an empty array" do
        result = with_context { attribute.value }

        expect(result).to eq([])
      end
    end
  end

  describe "Template integration" do
    let(:template) { SpecForge::Attribute::Template.new(input) }

    context "when used inside a template" do
      let(:input) { "{{ generate.array }}" }

      it "is not supported in template syntax" do
        # generate.array requires keyword arguments, so it can't be used
        # in {{ }} template syntax - it must be used in key position
        templates = template.instance_variable_get(:@templates)
        # Should fall back to Variable since it doesn't match the key-position pattern
        expect(templates.values.first).to be_a(SpecForge::Attribute::Variable)
      end
    end
  end
end
