# frozen_string_literal: true

RSpec.describe SpecForge::Factory do
  describe ".load_from_files" do
    around do |example|
      original_path = SpecForge.forge_path
      SpecForge.instance_variable_set(:@forge_path, fixtures_path)
      example.run
      SpecForge.instance_variable_set(:@forge_path, original_path)
    end

    it "loads factories from YAML files with filename-based naming" do
      factories = described_class.load_from_files

      expect(factories).to be_an(Array)
      expect(factories.size).to eq(1)

      factory = factories.first
      # Factory name comes from filename (test_product.yml -> :test_product)
      expect(factory.name).to eq(:test_product)
      expect(factory.model_class).to eq("Product")
      expect(factory.attributes[:name].resolved).to eq("Test Product")
      expect(factory.attributes[:price].resolved).to eq(9.99)
    end

    it "loads traits from the factory file" do
      factories = described_class.load_from_files

      factory = factories.first
      expect(factory.traits).to be_a(Hash)
      expect(factory.traits).to have_key(:premium)
      expect(factory.traits[:premium][:price].resolved).to eq(99.99)
      expect(factory.traits[:premium][:premium].resolved).to eq(true)
    end
  end

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

    context "when variables are defined" do
      let(:input) do
        {
          name: "test",
          variables: {
            var_1: "test_value"
          },
          attributes: {
            attr_1: "static_value"
          }
        }
      end

      it "stores variables as Attributes" do
        expect(factory.variables[:var_1]).to be_a(SpecForge::Attribute)
        expect(factory.variables[:var_1].resolved).to eq("test_value")
      end

      it "stores attributes as Attributes" do
        expect(factory.attributes[:attr_1]).to be_a(SpecForge::Attribute)
        expect(factory.attributes[:attr_1].resolved).to eq("static_value")
      end
    end

    context "when attributes use template syntax" do
      let(:input) do
        {
          name: "test",
          variables: {
            var_1: "template_value"
          },
          attributes: {
            attr_1: "{{ var_1 }}"
          }
        }
      end

      it "creates Template attributes that can reference variables" do
        expect(factory.attributes[:attr_1]).to be_a(SpecForge::Attribute::Template)
      end
    end

    context "when traits are defined" do
      let(:input) do
        {
          name: "test",
          attributes: {
            role: "user"
          },
          traits: {
            admin: {
              role: "admin"
            },
            verified: {
              verified: true
            }
          }
        }
      end

      it "stores traits as a hash of Attribute hashes" do
        expect(factory.traits).to be_a(Hash)
        expect(factory.traits).to have_key(:admin)
        expect(factory.traits).to have_key(:verified)
      end

      it "converts trait attributes to Attribute objects" do
        expect(factory.traits[:admin][:role]).to be_a(SpecForge::Attribute)
        expect(factory.traits[:admin][:role].resolved).to eq("admin")
        expect(factory.traits[:verified][:verified]).to be_a(SpecForge::Attribute)
        expect(factory.traits[:verified][:verified].resolved).to eq(true)
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

    context "when the factory has traits" do
      let(:name) { "employee" }
      let(:attributes) { {role: "employee", admin: false} }
      let(:traits) do
        {
          admin: {
            role: "admin",
            admin: true
          }
        }
      end

      subject(:factory) { SpecForge::Factory.new(name:, model_class: "Employee", attributes:, traits:) }

      before do
        stub_const(
          "Employee", Class.new do
            attr_accessor :role, :admin
          end
        )
      end

      it "registers traits with FactoryBot" do
        factory.register

        # Build without trait
        employee = FactoryBot.build(:employee)
        expect(employee.role).to eq("employee")
        expect(employee.admin).to eq(false)

        # Build with trait
        admin = FactoryBot.build(:employee, :admin)
        expect(admin.role).to eq("admin")
        expect(admin.admin).to eq(true)
      end
    end
  end
end
