# frozen_string_literal: true

RSpec.describe SpecForge::Factory do
  describe ".load_and_register" do
    let(:path) { SpecForge.root.join(".spec_forge") }

    let(:factory_names) do
      Dir[path.join("factories", "**/*.yml")].flat_map do |file_path|
        YAML.load_file(file_path).keys
      end
    end

    subject(:factories) { described_class.load_and_register(path) }

    context "when all factories are valid" do
      it "loads the factories yml as an object and registers it with FactoryBot" do
        expect(factories).to be_kind_of(Array)
        expect(factories.size).to be > 0

        factory_names.each do |name|
          bot_factory = FactoryBot::Internal.factory_by_name(name)
          expect(bot_factory).not_to be(nil),
            "Factory #{name} was defined but failed to register with FactoryBot"
        end
      end
    end

    context "when there is a duplicated factory" do
      let!(:factory) { SpecForge::Factory.new(name: "user").register_with_factory_bot }

      it "is expected to raise" do
        expect { factories }.to raise_error(FactoryBot::DuplicateDefinitionError)
      end
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
      factory.register_with_factory_bot

      bot_factory = FactoryBot::Internal.factory_by_name(name)
      expect(bot_factory).not_to be(nil)

      user = FactoryBot.build(:user)
      expect(user).not_to be(nil)
      expect(user.name).to eq(attributes[:name].value)
    end
  end
end
