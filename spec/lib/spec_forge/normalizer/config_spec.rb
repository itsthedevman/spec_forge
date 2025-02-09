# frozen_string_literal: true

# This is more for organizational purposes
RSpec.describe SpecForge::Normalizer do
  describe ".normalize_config!" do
    let(:config) do
      {
        environment: {
          use: "rails",
          preload: "some_path/preload.rb",
          models_path: "some_path/models"
        },
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

    ################################################################################################

    context "when aliases are used" do
      before do
        config[:environment][:models] = config[:environment].delete(:models)
      end

      it do
        expect(normalized[:models_path]).to eq(config[:environment][:models])
      end
    end

    ################################################################################################

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

    ################################################################################################

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

    ################################################################################################

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

    ################################################################################################

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

    ################################################################################################

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

    ################################################################################################

    context "when 'environment' is nil" do
      before do
        config[:environment] = nil
      end

      it do
        expect(normalized[:environment]).to eq("rails")
      end
    end

    context "when 'environment' is not a Hash" do
      before do
        config[:environment] = 1
      end

      it do
        expect { normalized }.to raise_error(
          SpecForge::InvalidStructureError,
          "Expected String or Hash, got Integer for \"environment\" on config"
        )
      end
    end

    context "when 'environment' is a String" do
      before do
        config[:environment] = "sinatra"
      end

      it do
        expect(normalized[:environment]).to eq("sinatra")
      end
    end

    context "when 'environment' is a Hash" do
      before do
        config[:environment] = {
          use: "rails"
        }
      end

      it do
        expect(normalized[:environment]).to eq(use: "rails", preload: "", models_path: "")
      end
    end

    ################################################################################################

    # preload
    # models_path
    context "when 'environment.use' is nil" do
      before do
        config[:environment][:use] = nil
      end

      it do
        expect(normalized[:environment][:use]).to eq("rails")
      end
    end

    context "when 'environment.use' is not a String" do
      before do
        config[:environment][:use] = 1
      end

      it do
        expect { normalized }.to raise_error(
          SpecForge::InvalidStructureError,
          "Expected String, got Integer for \"use\" on config"
        )
      end
    end

    ################################################################################################

    # models_path
    context "when 'environment.preload' is nil" do
      before do
        config[:environment][:preload] = nil
      end

      it do
        expect(normalized[:environment][:preload]).to eq("")
      end
    end

    context "when 'environment.preload' is not a String" do
      before do
        config[:environment][:preload] = 1
      end

      it do
        expect { normalized }.to raise_error(
          SpecForge::InvalidStructureError,
          "Expected String, got Integer for \"preload\" on config"
        )
      end
    end

    ################################################################################################

    context "when 'environment.models_path' is nil" do
      before do
        config[:environment][:models_path] = nil
      end

      it do
        expect(normalized[:environment][:models_path]).to eq("")
      end
    end

    context "when 'environment.models_path' is not a String" do
      before do
        config[:environment][:models_path] = 1
      end

      it do
        expect { normalized }.to raise_error(
          SpecForge::InvalidStructureError,
          "Expected String, got Integer for \"models_path\" on config"
        )
      end
    end
  end
end
