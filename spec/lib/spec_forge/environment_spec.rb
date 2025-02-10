# frozen_string_literal: true

RSpec.describe SpecForge::Environment do
  context "when 'rails' is used for the environment" do
    let(:path) { SpecForge.root.join("config", "application") }

    subject(:environment) { described_class.new }

    before do
      SpecForge.config.environment.use = "rails"

      # Mock File.exist?
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?)
        .with(path)
        .and_return(true)
    end

    it "is expected to require the file" do
      expect_any_instance_of(SpecForge::Environment).to receive(:require)
        .with(path)
        .and_return(true)

      environment.load
    end
  end

  context "when 'models_path' is defined" do
    let(:path) { SpecForge.root.join("spec", "support", "models") }

    subject(:environment) { described_class.new }

    before do
      SpecForge.config.environment.use = ""
      SpecForge.config.environment.models_path = path.to_s

      # Mock File.exist?
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?)
        .with(path.to_s)
        .and_return(true)
    end

    it "is expected to require the file" do
      expect_any_instance_of(SpecForge::Environment).to receive(:require)
        .with(path.join("person.rb").to_s)
        .and_call_original

      environment.load

      expect(defined?(Person)).to eq("constant")
    end
  end

  context "when 'preload' is defined" do
    let(:path) { SpecForge.root.join("spec", "support", "preload") }

    subject(:environment) { described_class.new }

    before do
      SpecForge.config.environment.use = ""
      SpecForge.config.environment.preload = path

      # Mock File.exist?
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?)
        .with(path)
        .and_return(true)
    end

    it "is expected to require the file" do
      expect_any_instance_of(SpecForge::Environment).to receive(:require)
        .with(path)
        .and_call_original

      environment.load

      expect(PRELOAD_REQUIRED).to be(true)
    end
  end
end
