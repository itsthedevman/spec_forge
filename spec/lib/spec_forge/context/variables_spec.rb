# frozen_string_literal: true

RSpec.describe SpecForge::Context::Variables do
  let(:base) {}
  let(:overlay) {}

  subject(:variables) { described_class.new(base:, overlay:) }

  describe "#[]" do
    context "when only 'base' is provided" do
      let(:base) { {var_1: 1, var_2: 2} }

      it "is expected to return the base variables" do
        expect(variables[:var_1]).to eq(1)
        expect(variables[:var_2]).to eq(2)
      end
    end

    context "when 'overlay' is provided but #use_overlay has not been called" do
      let(:base) { {var_1: 1, var_2: 2} }
      let(:overlay) { {my_overlay: {var_1: 2}} }

      it "is expected to return the base variables" do
        expect(variables[:var_1]).to eq(1)
        expect(variables[:var_2]).to eq(2)
      end
    end

    context "when 'overlay' is provided but #use_overlay has been called" do
      let(:base) { {var_1: 1, var_2: 2} }
      let(:overlay) { {my_overlay: {var_1: 2}} }

      before { variables.use_overlay(:my_overlay) }

      it "is expected to return the overlaid variables" do
        expect(variables[:var_1]).to eq(2)
        expect(variables[:var_2]).to eq(2)
      end
    end
  end

  describe "#to_h" do
    let(:base) { {var_1: 2} }

    it "is expected to return the active variables" do
      expect(variables.to_h).to eq(base)
    end
  end

  describe "#resolve" do
    let(:base) { {var_1: "faker.string.random"} }

    subject(:resolved_h) { variables.resolve }

    it "is expected to return the resolved variables" do
      expect(resolved_h[:var_1]).not_to eq("faker.string.random")
      expect(resolved_h[:var_1]).to be_kind_of(String)
    end
  end

  describe "#use_overlay" do
    let(:base) { {var_2: Faker::String.random} }
    let(:overlay) { {my_other_overlay: {var_1: "Hello"}} }

    it "is expected to return the overlaid variables" do
      variables.use_overlay(:my_other_overlay)
      expect(variables.to_h).to eq(var_1: "Hello", var_2: base[:var_2])
    end
  end
end
