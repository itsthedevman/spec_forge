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

  context "when the faker path has subclasses" do
    let(:path) { "faker.games.zelda.game" }

    it "parses the faker class and method" do
      expect(attribute.faker_class).to eq(Faker::Games::Zelda)
      expect(attribute.faker_method).to eq(Faker::Games::Zelda.method(:game))
    end
  end

  context "when the faker path is not valid" do
    context "due to the class not being valid" do
      let(:path) { "faker.noop.does_not_exist" }

      it "is expected to raise" do
        expect { attribute }.to raise_error(SpecForge::InvalidFakerClassError)
      end
    end

    context "due to the method not being valid" do
      let(:path) { "faker.string.does_not_exist" }

      it "is expected to raise" do
        expect { attribute }.to raise_error(SpecForge::InvalidFakerMethodError)
      end
    end
  end

  context "when the Faker method takes positional arguments" do
    let(:path) { "faker.forge.positional" }

    before do
      # Apparently, Faker is good at always having a default lol
      stub_const(
        "Faker::Forge", Class.new do
          def self.positional(required, optional = [])
            [required, optional]
          end
        end
      )
    end

    context "and the arguments are not provided" do
      it "is expected to raise" do
        expect { attribute.value }.to raise_error(ArgumentError)
      end
    end

    context "and the required arguments are provided" do
      let(:positional) { [10] }

      it "is expected to work" do
        expect(attribute.value).to eq([10, []])
      end
    end

    context "and all arguments are provided" do
      let(:positional) { [10, 20] }

      it "is expected to work" do
        expect(attribute.value).to eq([10, 20])
      end
    end
  end

  context "when the Faker method takes keyword arguments" do
    let(:path) { "faker.forge.keyword" }

    before do
      # Apparently, Faker is good at always having a default lol
      stub_const(
        "Faker::Forge", Class.new do
          def self.keyword(required:, optional: [])
            [required, optional]
          end
        end
      )
    end

    context "and the arguments are not provided" do
      it "is expected to raise" do
        expect { attribute.value }.to raise_error(ArgumentError)
      end
    end

    context "and the required arguments are provided" do
      let(:keyword) { {required: 10} }

      it "is expected to work" do
        expect(attribute.value).to eq([10, []])
      end
    end

    context "and all arguments are provided" do
      let(:keyword) { {required: 10, optional: 20} }

      it "is expected to work" do
        expect(attribute.value).to eq([10, 20])
      end
    end
  end
end
