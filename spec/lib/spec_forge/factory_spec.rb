# frozen_string_literal: true

RSpec.describe SpecForge::Factory do
  describe ".load_and_register" do
    let(:path) { SpecForge.forge_path }

    subject(:factories) { described_class.load_and_register }

    context "when 'auto_discovery' is enabled and factories exist" do
      it "loads them" do
        factories # Call load_and_register

        # As defined in spec/factories/auto_discoverable.rb
        bot_factory = FactoryBot::Internal.factory_by_name("auto_discoverable")
        expect(bot_factory).not_to be(nil)
      end
    end

    context "when 'factories.paths' is set" do
      let!(:paths_before) { FactoryBot.definition_file_paths }

      before do
        SpecForge.configuration.factories.paths = ["test"]
      end

      after do
        # Important! It changes this value
        FactoryBot.definition_file_paths = paths_before
      end

      it "is expected that FactoryBot's definition paths is changed" do
        factories # Trigger the call
        expect(FactoryBot.definition_file_paths).to eq(["test"])
      end
    end
  end

  describe "#initialize" do
    let(:input) {}

    subject(:factory) { described_class.new(**input) }

    context "when variables are referenced" do
      let(:input) do
        {
          name: "test",
          variables: {
            var_1: "test"
          },
          attributes: {
            attr_1: "variables.var_1"
          }
        }
      end

      it "is expected that they are properly linked" do
        expect(factory.attributes[:attr_1].value).to eq(input[:variables][:var_1])
      end
    end

    context "when 'variables' reference themselves" do
      let(:input) do
        {
          name: "test",
          variables: {
            var_1: "test",
            var_2: "variables.var_1"
          },
          attributes: {}
        }
      end

      it "is expected to be able to be resolved" do
        expect(factory.variables[:var_2].resolve).to eq(input[:variables][:var_1])
      end
    end
  end

  describe "#register" do
    context "when the factory is valid" do
      let!(:factory) { SpecForge::Factory.new(name: "user").register }

      it "is expected register it with FactoryBot" do
        bot_factory = FactoryBot::Internal.factory_by_name("user")
        expect(bot_factory).not_to be(nil),
          "Factory \"user\" was defined but failed to register with FactoryBot"
      end
    end

    context "when there is a duplicated factory" do
      let!(:factory) { SpecForge::Factory.new(name: "user").register }
      let(:factory_2) { SpecForge::Factory.new(name: "user").register }

      it "is expected to raise" do
        expect { factory_2 }.to raise_error(FactoryBot::DuplicateDefinitionError)
      end
    end

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

      it "register successfully and can be built by FactoryBot" do
        factory.register

        bot_factory = FactoryBot::Internal.factory_by_name(name)
        expect(bot_factory).not_to be(nil)

        user = FactoryBot.build(:user)
        expect(user).not_to be(nil)
        expect(user.name).to eq(attributes[:name])
      end
    end
  end
end
