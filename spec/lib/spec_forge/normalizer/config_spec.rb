# frozen_string_literal: true

# This is more for organizational purposes
RSpec.describe SpecForge::Normalizer do
  describe ".normalize_config!" do
    let(:config) do
      {
        base_url: "http://localhost:3000",
        authorization: {
          default: {
            header: "Authorization",
            value: ""
          }
        },
        factories: {
          paths: [],
          auto_discover: true
        }
      }
    end

    subject(:normalized) { described_class.normalize_config!(config) }

    it "is expected to normalize fully" do
      expect(normalized[:base_url]).to eq(config[:base_url])
      expect(normalized[:authorization]).to eq(config[:authorization])
    end

    context "when 'base_url' is nil" do
      before do
        config[:base_url] = nil
      end

      it do
        expect { normalized }.to raise_error(
          SpecForge::InvalidStructureError,
          "Expected String, got NilClass for \"base_url\" on config"
        )
      end
    end

    context "when 'base_url' is not a String" do
      before do
        config[:base_url] = 1
      end

      it do
        expect { normalized }.to raise_error(
          SpecForge::InvalidStructureError,
          "Expected String, got Integer for \"base_url\" on config"
        )
      end
    end

    context "when 'authorization' is nil" do
      before do
        config[:authorization] = nil
      end

      it do
        expect(normalized[:authorization]).to eq(
          default: {header: "", value: ""}
        )
      end
    end

    context "when 'authorization' is not a Hash" do
      before do
        config[:authorization] = 1
      end

      it do
        expect { normalized }.to raise_error(
          SpecForge::InvalidStructureError,
          "Expected Hash, got Integer for \"authorization\" on config"
        )
      end
    end

    context "when 'factories' is nil" do
      before do
        config[:factories] = nil
      end

      it do
        expect(normalized[:factories]).to eq(
          paths: [], auto_discover: true
        )
      end
    end

    context "when 'factories' is not a Hash" do
      before do
        config[:factories] = 1
      end

      it do
        expect { normalized }.to raise_error(
          SpecForge::InvalidStructureError,
          "Expected Hash, got Integer for \"factories\" on config"
        )
      end
    end

    context "when 'factories.paths' is nil" do
      before do
        config[:factories][:paths] = nil
      end

      it do
        expect(normalized[:factories][:paths]).to eq([])
      end
    end

    context "when 'factories.paths' is not an Array" do
      before do
        config[:factories][:paths] = 1
      end

      it do
        expect { normalized }.to raise_error(
          SpecForge::InvalidStructureError,
          "Expected Array, got Integer for \"paths\" on config"
        )
      end
    end

    context "when 'factories.auto_discover' is nil" do
      before do
        config[:factories][:auto_discover] = nil
      end

      it do
        expect(normalized[:factories][:auto_discover]).to be(true)
      end
    end

    context "when 'factories.auto_discover' is false" do
      before do
        config[:factories][:auto_discover] = false
      end

      it do
        expect(normalized[:factories][:auto_discover]).to be(false)
      end
    end

    context "when 'factories.auto_discover' is not a Boolean" do
      before do
        config[:factories][:auto_discover] = 1
      end

      it do
        expect { normalized }.to raise_error(
          SpecForge::InvalidStructureError,
          "Expected TrueClass or FalseClass, got Integer for \"auto_discover\" on config"
        )
      end
    end
  end
end
