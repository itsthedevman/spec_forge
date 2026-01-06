# frozen_string_literal: true

RSpec.describe SpecForge::Attribute::Factory do
  let(:input) { "factories.user" }

  let(:positional) { [] }
  let(:keyword) { {} }

  subject(:factory) { described_class.new(input, positional, keyword) }

  before do
    stub_const(
      "User",
      Class.new do
        attr_accessor :name

        def chained
          Data.define(:variable).new(variable: 1)
        end

        def save! # Created by FactoryBot.create
          true
        end
      end
    )

    SpecForge::Factory.new(name: :user, model_class: "User", attributes: {name: "Bob"}).register
  end

  include_examples "from_input_to_attribute" do
    let(:input) { "factories.user" }
  end

  context "when just the factory name is referenced" do
    it "is expected to load the factory" do
      expect(factory.factory_name).to eq(:user)
      expect(factory.value).to be_kind_of(User)
    end
  end

  context "when the result is chained" do
    let(:input) { "factories.user.chained.variable" }

    it "is expected to load the factory" do
      expect(factory.factory_name).to eq(:user)
      expect(factory.value).to eq(1)
    end
  end

  context "when 'resolve' is called" do
    it "is expected to work" do
      expect(factory.resolved).to be_kind_of(User)
    end
  end

  context "when the expanded form is used" do
    context "and 'attributes' is provided" do
      let(:keyword) do
        {attributes: {name: "Billy"}}
      end

      it "is expected to override the existing attributes" do
        expect(factory.value.name).to eq("Billy")
      end
    end

    context "and 'strategy' is 'build'" do
      let(:keyword) do
        {strategy: "build"}
      end

      it "is expected to build" do
        expect_any_instance_of(User).not_to receive(:save!)

        expect(factory.value).to be_kind_of(User)
      end
    end

    context "and 'strategy' is 'attributes_for'" do
      let(:keyword) do
        {strategy: "attributes_for"}
      end

      it "is expected to build attributes for it" do
        expect_any_instance_of(User).not_to receive(:save!)

        expect(factory.value).to be_kind_of(Hash).and(match(name: "Bob"))
      end
    end

    context "and 'strategy' is 'build_stubbed'" do
      let(:keyword) do
        {strategy: "build_stubbed"}
      end

      it "is expected to receive a stubbed object" do
        expect(User.instance_methods).not_to include("persisted?")
        expect(factory.value).to respond_to(:persisted?)
      end
    end

    context "and 'strategy' is 'build_list'" do
      let(:keyword) do
        {strategy: "build_list", size: 5}
      end

      it "is expected to build a list of users" do
        expect_any_instance_of(User).not_to receive(:save!)

        users = factory.resolved

        expect(users.size).to eq(5)
        expect(users).to be_all(be_kind_of(User))
      end
    end

    context "and 'strategy' is 'create_list'" do
      let(:keyword) do
        {strategy: "create_list", size: 3}
      end

      it "is expected to create a list of users" do
        save_count = 0
        allow_any_instance_of(User).to receive(:save!) do |instance|
          save_count += 1
          true
        end

        users = factory.resolved

        expect(users.size).to eq(3)
        expect(save_count).to eq(3)
        expect(users).to be_all(be_kind_of(User))
      end
    end

    context "and 'strategy' is 'attributes_for_list'" do
      let(:keyword) do
        {strategy: "attributes_for_list", size: 20}
      end

      it "is expected to build a list of attributes for a user" do
        expect_any_instance_of(User).not_to receive(:save!)

        users = factory.resolved

        expect(users.size).to eq(20)
        expect(users).to be_all(be_kind_of(Hash))
      end
    end

    context "and 'strategy' is 'build_stubbed_list'" do
      let(:keyword) do
        {strategy: "build_stubbed_list", size: 15}
      end

      it "is expected to build a list of attributes for a user" do
        expect_any_instance_of(User).not_to receive(:save!)

        expect(User.instance_methods).not_to include("persisted?")

        users = factory.resolved

        expect(users.size).to eq(15)
        expect(users).to be_all(be_kind_of(User))
        expect(users).to be_all(respond_to(:persisted?))
      end
    end

    context "and 'strategy' is 'build_pair'" do
      let(:keyword) do
        {strategy: "build_pair"}
      end

      it "is expected to build a pair of users" do
        expect_any_instance_of(User).not_to receive(:save!)

        users = factory.resolved

        expect(users.size).to eq(2)
        expect(users).to be_all(be_kind_of(User))
      end
    end

    context "and 'strategy' is 'create_pair'" do
      let(:keyword) do
        {strategy: "create_pair"}
      end

      it "is expected to create a pair of users" do
        save_count = 0
        allow_any_instance_of(User).to receive(:save!) do |instance|
          save_count += 1
          true
        end

        users = factory.resolved

        expect(users.size).to eq(2)
        expect(save_count).to eq(2)
        expect(users).to be_all(be_kind_of(User))
      end
    end
  end

  describe "#resolve" do
    context "when value is an array" do
      let(:keyword) { {strategy: "build_list", size: 2} }

      it "maps resolve over each element" do
        result = factory.resolve
        expect(result).to be_an(Array)
        expect(result.size).to eq(2)
        expect(result).to all(be_a(User))
      end
    end

    context "when value is a hash" do
      let(:keyword) { {strategy: "attributes_for"} }

      it "transforms values with resolve" do
        result = factory.resolve
        expect(result).to be_a(Hash)
        expect(result[:name]).to eq("Bob")
      end
    end

    context "when value is a simple object" do
      let(:keyword) { {strategy: "build"} }

      it "returns the value directly" do
        result = factory.resolve
        expect(result).to be_a(User)
      end
    end
  end

  describe "invalid build strategy" do
    let(:keyword) { {strategy: "invalid_strategy"} }

    it "raises InvalidBuildStrategy error" do
      expect { factory.resolved }.to raise_error(SpecForge::Error::InvalidBuildStrategy)
    end
  end

  describe "#construct_factory_parameters" do
    subject(:parameters) do
      # Private method and all - I don't usually test private methods
      factory.send(:construct_factory_parameters, factory.arguments[:keyword])
    end

    context "when the strategy is 'build' and size is not provided" do
      let(:keyword) do
        {strategy: "build"}
      end

      it { is_expected.to eq(["build", :user]) }
    end

    context "when the strategy is 'create' and size is not provided" do
      let(:keyword) do
        {strategy: "create"}
      end

      it { is_expected.to eq(["create", :user]) }
    end

    context "when the strategy is 'stubbed' and size is not provided" do
      let(:keyword) do
        {strategy: "stubbed"}
      end

      it { is_expected.to eq(["build_stubbed", :user]) }
    end

    context "when the strategy is 'build_stubbed' and size is not provided" do
      let(:keyword) do
        {strategy: "build_stubbed"}
      end

      it { is_expected.to eq(["build_stubbed", :user]) }
    end

    context "when the strategy is 'attributes_for' and size is not provided" do
      let(:keyword) do
        {strategy: "attributes_for"}
      end

      it { is_expected.to eq(["attributes_for", :user]) }
    end

    context "when the strategy is 'build' and size is provided" do
      let(:keyword) do
        {strategy: "build", size: 1}
      end

      it { is_expected.to eq(["build_list", :user, 1]) }
    end

    context "when the strategy is 'create' and size is provided" do
      let(:keyword) do
        {strategy: "create", size: 2}
      end

      it { is_expected.to eq(["create_list", :user, 2]) }
    end

    context "when the strategy is 'stubbed' and size is provided" do
      let(:keyword) do
        {strategy: "stubbed", size: 3}
      end

      it { is_expected.to eq(["build_stubbed_list", :user, 3]) }
    end

    context "when the strategy is 'build_stubbed' and size is provided" do
      let(:keyword) do
        {strategy: "build_stubbed", size: 3}
      end

      it { is_expected.to eq(["build_stubbed_list", :user, 3]) }
    end

    context "when the strategy is 'attributes_for' and size is provided" do
      let(:keyword) do
        {strategy: "attributes_for", size: 4}
      end

      it { is_expected.to eq(["attributes_for_list", :user, 4]) }
    end

    context "when the strategy is 'build_list' and size is provided" do
      let(:keyword) do
        {strategy: "build_list", size: 1}
      end

      it { is_expected.to eq(["build_list", :user, 1]) }
    end

    context "when the strategy is 'create_list' and size is provided" do
      let(:keyword) do
        {strategy: "create_list", size: 1}
      end

      it { is_expected.to eq(["create_list", :user, 1]) }
    end

    context "when the strategy is 'stubbed_list' and size is provided" do
      let(:keyword) do
        {strategy: "stubbed_list", size: 1}
      end

      it { is_expected.to eq(["build_stubbed_list", :user, 1]) }
    end

    context "when the strategy is 'build_stubbed_list' and size is provided" do
      let(:keyword) do
        {strategy: "build_stubbed_list", size: 1}
      end

      it { is_expected.to eq(["build_stubbed_list", :user, 1]) }
    end

    context "when the strategy is 'attributes_for_list' and size is provided" do
      let(:keyword) do
        {strategy: "attributes_for_list", size: 1}
      end

      it { is_expected.to eq(["attributes_for_list", :user, 1]) }
    end

    context "when the strategy is 'build_pair' and size is provided" do
      let(:keyword) do
        {strategy: "build_pair", size: 2}
      end

      # Size is ignored
      it { is_expected.to eq(["build_pair", :user]) }
    end

    context "when the strategy is 'create_pair' and size is provided" do
      let(:keyword) do
        {strategy: "create_pair", size: 2}
      end

      # Size is ignored
      it { is_expected.to eq(["create_pair", :user]) }
    end
  end
end
