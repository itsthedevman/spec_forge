# frozen_string_literal: true

RSpec.describe SpecForge::Factory do
  context "when the factory has a valid model class" do
    let(:attributes) { {name: Faker::String.random} }
    let(:name) { "user" }

    subject(:factory) { SpecForge::Factory.new(name:, model_class: "User", attributes:) }

    before do
      stub_const(
        "User", Class.new do
          attr_accessor :name
        end
      )
    end

    it "defines successfully" do
      factory.register_with_factory_bot

      bot_factory = FactoryBot::Internal.factory_by_name(name)
      expect(bot_factory).not_to be(nil)

      user = FactoryBot.build(:user)
      expect(user).not_to be(nil)
      expect(user.name).to eq(attributes[:name].value)
    end
  end
end
