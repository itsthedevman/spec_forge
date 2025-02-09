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
  end

  context "when 'resolve' is called" do
    it "is expected to work" do
      expect(factory.resolve).to be_kind_of(User)
    end
  end
end
