# frozen_string_literal: true

RSpec.describe SpecForge::Attribute::Faker do
  let(:path) { "" }
  let(:positional) { [] }
  let(:keyword) { {} }

  subject(:attribute) { described_class.new(path, positional, keyword) }

  context "when the faker path is valid" do
    let(:path) { "faker.number.positive" }

    it "parses the faker class and method" do
      expect(attribute.faker_class).to eq(Faker::Number)
      expect(attribute.faker_method).to eq(Faker::Number.method(:positive))
    end
  end

  context "when the faker path is not valid" do
    context "due to the class not being valid" do
      let(:path) { "faker.does_not_exist" }

      it "is expected to raise" do
        expect { attribute }.to raise_error(SpecForge::InvalidFakerClass)
      end
    end

    context "due to the method not being valid" do
      let(:path) { "faker.string.does_not_exist" }

      it "is expected to raise" do
        expect { attribute }.to raise_error(SpecForge::InvalidFakerMethod)
      end
    end
  end

  context "when the Faker method takes positional arguments"
  context "when the Faker method takes keyword arguments"
end
