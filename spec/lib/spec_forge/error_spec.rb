# frozen_string_literal: true

RSpec.describe SpecForge::Error do
  describe SpecForge::InvalidFakerClass do
  end

  describe SpecForge::InvalidFakerMethod do
    let(:input) { "psoitive" }

    subject(:error) { SpecForge::InvalidFakerMethod.new(input, Faker::Number) }

    it "will provide them in the error" do
      expect(error.message).to match("Did you mean?")
    end
  end
end
