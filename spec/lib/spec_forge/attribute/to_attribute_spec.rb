# frozen_string_literal: true

RSpec.describe SpecForge::Attribute::ToAttribute do
  let(:test_class) do
    Class.new do
      include SpecForge::Attribute::ToAttribute

      attr_reader :value

      def initialize(value)
        @value = value
      end
    end
  end

  subject(:instance) { test_class.new("test") }

  describe "#to_attribute" do
    it "is expected to convert the object to an Attribute" do
      result = instance.to_attribute

      expect(result).to be_kind_of(SpecForge::Attribute)
    end

    it "is expected to delegate to Attribute.from" do
      allow(SpecForge::Attribute).to receive(:from).and_call_original

      instance.to_attribute

      expect(SpecForge::Attribute).to have_received(:from).with(instance)
    end
  end
end
