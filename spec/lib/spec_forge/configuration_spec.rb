# frozen_string_literal: true

RSpec.describe SpecForge::Configuration do
  subject(:configuration) { described_class.new }

  describe "#validate" do
    let(:base_url) { "http://localhost:3001" }

    let(:headers) do
      {
        "Authorization" => "Bearer Bear",
        :header_1 => "value_1"
      }
    end

    let(:query) do
      {
        query_1: "value_1"
      }
    end

    let(:factories) do
      {
        auto_discover: false,
        paths: ["some/path"]
      }
    end

    let(:on_debug) do
      -> {}
    end

    let(:config) do
      SpecForge.configure do |config|
        config.base_url = base_url
        config.headers = headers
        config.query = query
        config.factories = factories
        config.on_debug_proc = on_debug
      end
    end

    subject(:validated) { config.validate }

    it "validates successfully" do
      expect { validated }.not_to raise_error

      expect(config.base_url).to eq(base_url)
      expect(config.headers).to eq(headers)
      expect(config.query).to eq(query)
      expect(config.on_debug_proc).to eq(on_debug)
    end

    context "when 'base_url' is nil" do
      let(:base_url) { nil }

      it do
        expect { validated }.to raise_error(
          SpecForge::Error::InvalidStructureError,
          "Expected String, got NilClass for \"base_url\" in configuration"
        )
      end
    end

    context "when 'base_url' is not a String" do
      let(:base_url) { 1 }

      it do
        expect { validated }.to raise_error(
          SpecForge::Error::InvalidStructureError,
          "Expected String, got Integer for \"base_url\" in configuration"
        )
      end
    end

    context "when 'headers' is nil" do
      let(:headers) { nil }

      it do
        expect { validated }.not_to raise_error
        expect(config.headers).to eq({})
      end
    end

    context "when 'headers' is not a Hash" do
      let(:headers) { 1 }

      it do
        expect { validated }.to raise_error(
          SpecForge::Error::InvalidStructureError,
          "Expected Hash, got Integer for \"headers\" in configuration"
        )
      end
    end

    context "when 'query' is nil" do
      let(:query) { nil }

      it do
        expect { validated }.not_to raise_error
        expect(config.query).to eq({})
      end
    end

    context "when 'query' is not a hash" do
      let(:query) { 1 }

      it do
        expect { validated }.to raise_error(
          SpecForge::Error::InvalidStructureError,
          "Expected Hash or String, got Integer for \"query\" (aliases \"params\") in configuration"
        )
      end
    end

    context "when 'on_debug_proc' is nil" do
      let(:on_debug) { nil }

      it do
        expect { validated }.to raise_error(
          SpecForge::Error::InvalidStructureError,
          "Expected Proc, got NilClass for \"on_debug_proc\" in configuration"
        )
      end
    end

    context "when 'on_debug_proc' is not a proc" do
      let(:on_debug) { 1 }

      it do
        expect { validated }.to raise_error(
          SpecForge::Error::InvalidStructureError,
          "Expected Proc, got Integer for \"on_debug_proc\" in configuration"
        )
      end
    end
  end

  describe "#register_callback/#define_callback/#callback" do
    it "is expected to responds to all three" do
      is_expected.to respond_to(:register_callback)
      is_expected.to respond_to(:define_callback)
      is_expected.to respond_to(:callback)
    end

    it "is expected to register a callback" do
      configuration.callback(:callback_one) {}
      configuration.define_callback(:callback_two) {}
      configuration.register_callback(:callback_three) {}

      names = SpecForge::Callbacks.registered_names
      expect(names).to contain_exactly("callback_one", "callback_two", "callback_three")
    end
  end

  describe "#specs" do
    it { is_expected.to respond_to(:specs) }
    it { expect(configuration.specs).to be_kind_of(RSpec::Core::Configuration) }
  end
end
