# frozen_string_literal: true

RSpec.describe SpecForge::Error do
  describe SpecForge::InvalidFakerClassError do
    let(:input) { "faker.nuumbre" }

    subject(:error) { SpecForge::InvalidFakerClassError.new(input) }

    it "will provide them in the error" do
      expect(error.message).to match("Did you mean?")
    end
  end

  describe SpecForge::InvalidFakerMethodError do
    let(:input) { "psoitive" }

    subject(:error) { SpecForge::InvalidFakerMethodError.new(input, Faker::Number) }

    it "will provide them in the error" do
      expect(error.message).to match("Did you mean?")
    end
  end
end
