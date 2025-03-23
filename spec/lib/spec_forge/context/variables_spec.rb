# frozen_string_literal: true

RSpec.describe SpecForge::Context::Variables do
  let(:base) {}
  let(:overlay) {}

  subject(:variables) { described_class.new(base:, overlay:) }

  describe "#use_overlay" do
    context "when the overlay has new variables" do
      let(:base) { {var_2: Faker::String.random} }
      let(:overlay) { {my_other_overlay: {var_1: "Hello"}} }

      it "is expected to merge the two" do
        variables.use_overlay(:my_other_overlay)
        expect(variables.to_h).to eq(var_1: "Hello", var_2: base[:var_2])
      end
    end

    context "when the requested overlay is empty" do
      let(:base) { {var_1: 1, var_2: 2} }
      let(:overlay) { {overlay_1: {var_1: 2, var_2: 1}} }

      it "is expected to reset the variables back to base" do
        expect(variables).to match(var_1: 1, var_2: 2)

        variables.use_overlay(:overlay_1)
        expect(variables).to match(var_1: 2, var_2: 1)

        variables.use_overlay(:does_not_exist)
        expect(variables).to match(var_1: 1, var_2: 2)
      end
    end

    context "when the value is blank" do
      let(:base) { {var_1: "Something"} }
      let(:overlay) { {overlay_1: {var_1: ""}} }

      it "is expected to overwrite the base value" do
        expect(variables).to match(var_1: "Something")

        variables.use_overlay(:overlay_1)
        expect(variables).to match(var_1: "")
      end
    end
  end
end
