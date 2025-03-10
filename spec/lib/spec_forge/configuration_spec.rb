# frozen_string_literal: true

RSpec.describe SpecForge::Configuration do
  describe ".overlay_options" do
    let(:source) {}
    let(:overlay) {}

    subject(:overlaid) { described_class.overlay_options(source, overlay) }

    context "when the source value is nil" do
      let(:source) { {value: nil} }

      context "and the overlay value is empty" do
        let(:overlay) { {value: []} }

        it { expect(overlaid).to eq(value: []) }
      end

      context "and the overlay value is populated" do
        let(:overlay) { {value: "test"} }

        it do
          expect(overlaid).to eq(value: "test")
        end
      end
    end

    context "when the source value is blank" do
      context "and the overlay value is a populated string" do
        let(:source) { {value: ""} }
        let(:overlay) { {value: "test"} }

        it { expect(overlaid).to eq(value: "test") }
      end

      context "and the overlay value is a populated array" do
        let(:source) { {value: []} }
        let(:overlay) { {value: [1]} }

        it { expect(overlaid).to eq(value: [1]) }
      end

      context "and the overlay value is a populated hash" do
        let(:source) { {value: {}} }
        let(:overlay) { {value: {value_2: ""}} }

        it { expect(overlaid).to eq(value: {value_2: ""}) }
      end
    end

    context "when the source value is present" do
      let(:source) { {value: {value_2: true}} }

      context "and the overlay value is blank" do
        let(:overlay) { {value: nil} }

        it { expect(overlaid).to eq(value: {value_2: true}) }
      end

      context "and the overlay value is a populated hash" do
        let(:overlay) { {value: {value_1: false}} }

        it { expect(overlaid).to eq(value: {value_1: false, value_2: true}) }
      end

      context "and the overlay value overwrites an existing hash key" do
        let(:overlay) { {value: {value_2: false}} }

        it { expect(overlaid).to eq(value: {value_2: false}) }
      end
    end
  end

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
        config.on_debug = on_debug
      end
    end

    subject(:validated) { config.validate }

    it "validates successfully" do
      expect { validated }.not_to raise_error

      expect(config.base_url).to eq(base_url)
      expect(config.headers).to eq(headers)
      expect(config.query).to eq(query)
      expect(config.on_debug).to eq(on_debug)
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
          "Expected Hash, got Integer for \"query\" (aliases \"params\") in configuration"
        )
      end
    end

    context "when 'on_debug' is nil" do
      let(:on_debug) { nil }

      it do
        expect { validated }.to raise_error(
          SpecForge::Error::InvalidStructureError,
          "Expected Proc, got NilClass for \"on_debug\" in configuration"
        )
      end
    end

    context "when 'on_debug' is not a proc" do
      let(:on_debug) { 1 }

      it do
        expect { validated }.to raise_error(
          SpecForge::Error::InvalidStructureError,
          "Expected Proc, got Integer for \"on_debug\" in configuration"
        )
      end
    end
  end
end
