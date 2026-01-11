# frozen_string_literal: true

RSpec.describe SpecForge::Configuration do
  subject(:configuration) { described_class.new }

  describe "#initialize" do
    it "is expected to set default values" do
      expect(configuration.base_url).to eq("http://localhost:3000")
      expect(configuration.global_variables).to eq({})
      expect(configuration.factories).to be_a(described_class::Factories)
      expect(configuration.factories.auto_discover).to be true
      expect(configuration.factories.paths).to eq([])
    end
  end

  describe "#validate" do
    let(:base_url) { "http://localhost:3001" }

    let(:global_variables) do
      {
        api_version: "v1",
        admin_email: "admin@test.com"
      }
    end

    let(:config) do
      SpecForge.configure do |config|
        config.base_url = base_url
        config.global_variables = global_variables
      end
    end

    subject(:validated) { config.validate }

    it "is expected to validate successfully" do
      expect { validated }.not_to raise_error

      expect(config.base_url).to eq(base_url)
      expect(config.global_variables).to eq(global_variables)
    end

    it "is expected to return self for chaining" do
      expect(validated).to be(config)
    end

    context "when 'base_url' is nil" do
      let(:base_url) { nil }

      it "is expected to raise error" do
        expect { validated }.to raise_error(
          SpecForge::Error::InvalidStructureError,
          /Expected String, got NilClass for "base_url" in configuration/
        )
      end
    end

    context "when 'base_url' is not a String" do
      let(:base_url) { 123 }

      it "is expected to raise error" do
        expect { validated }.to raise_error(
          SpecForge::Error::InvalidStructureError,
          /Expected String, got Integer for "base_url" in configuration/
        )
      end
    end

    context "when 'global_variables' is nil" do
      let(:global_variables) { nil }

      it "is expected to not raise error and default to empty hash" do
        expect { validated }.not_to raise_error
        expect(config.global_variables).to eq({})
      end
    end

    context "when 'global_variables' is not a Hash" do
      let(:global_variables) { "not a hash" }

      it "is expected to raise error" do
        expect { validated }.to raise_error(
          SpecForge::Error::InvalidStructureError,
          /Expected Hash, got String for "global_variables" in configuration/
        )
      end
    end

    context "when 'global_variables' is blank after being set" do
      let(:global_variables) { {key: "value"} }

      it "is expected to restore default" do
        config.global_variables = nil
        validated

        expect(config.global_variables).to eq({})
      end
    end
  end

  describe "#factories" do
    it "is expected to return Factories instance" do
      expect(configuration.factories).to be_a(described_class::Factories)
    end

    it "is expected to not have a writer method" do
      expect(configuration).not_to respond_to(:factories=)
    end

    it "is expected to allow modification of factories attributes" do
      configuration.factories.auto_discover = false
      configuration.factories.paths << "custom/path"

      expect(configuration.factories.auto_discover).to be false
      expect(configuration.factories.paths).to eq(["custom/path"])
    end
  end

  describe "#register_callback" do
    it "is expected to register a callback with a block" do
      block = proc { puts "test" }
      configuration.register_callback(:test_callback, &block)

      callbacks = configuration.instance_variable_get(:@callbacks)
      expect(callbacks[:test_callback]).to eq(block)
    end

    it "is expected to convert string names to symbols" do
      block = proc { puts "test" }
      configuration.register_callback("string_callback", &block)

      callbacks = configuration.instance_variable_get(:@callbacks)
      expect(callbacks).to have_key(:string_callback)
    end
  end

  describe "#rspec" do
    it "is expected to respond to rspec" do
      expect(configuration).to respond_to(:rspec)
    end

    it "is expected to return RSpec configuration" do
      expect(configuration.rspec).to be_kind_of(RSpec::Core::Configuration)
    end
  end

  describe "#on_debug" do
    it "is expected to respond to on_debug" do
      expect(configuration).to respond_to(:on_debug)
    end

    it "is expected to set debug proc" do
      debug_proc = proc { puts "debugging" }
      configuration.on_debug(&debug_proc)

      stored_proc = configuration.instance_variable_get(:@on_debug_proc)
      expect(stored_proc).to eq(debug_proc)
    end
  end

  describe "#before" do
    let(:callback_block) { proc { |context| "before hook" } }

    before do
      configuration.register_callback(:my_callback, &callback_block)
    end

    it "is expected to attach a callback to a before event" do
      configuration.before(:each, :my_callback)

      events = configuration.instance_variable_get(:@events)
      expect(events[:before_each]).to include(callback_block)
    end

    it "is expected to accept string callback names and convert to symbols" do
      configuration.before(:each, "my_callback")

      events = configuration.instance_variable_get(:@events)
      expect(events[:before_each]).to include(callback_block)
    end

    context "when using valid events" do
      it "is expected to accept :forge event" do
        configuration.before(:forge, :my_callback)

        events = configuration.instance_variable_get(:@events)
        expect(events[:before_forge]).to include(callback_block)
      end

      it "is expected to accept :blueprint event" do
        configuration.before(:blueprint, :my_callback)

        events = configuration.instance_variable_get(:@events)
        expect(events[:before_blueprint]).to include(callback_block)
      end

      it "is expected to accept :each event" do
        configuration.before(:each, :my_callback)

        events = configuration.instance_variable_get(:@events)
        expect(events[:before_each]).to include(callback_block)
      end
    end

    context "when the event is invalid" do
      it "is expected to raise an ArgumentError" do
        expect { configuration.before(:invalid, :my_callback) }.to raise_error(
          ArgumentError,
          /Invalid event.*Expected one of/
        )
      end
    end

    context "when the callback is not registered" do
      it "is expected to raise an ArgumentError" do
        expect { configuration.before(:each, :unregistered_callback) }.to raise_error(
          ArgumentError,
          /Invalid callback/
        )
      end
    end

    context "when attaching the same callback to multiple events" do
      it "is expected to allow the callback to be reused" do
        configuration.before(:forge, :my_callback)
        configuration.before(:blueprint, :my_callback)
        configuration.before(:each, :my_callback)

        events = configuration.instance_variable_get(:@events)
        expect(events[:before_forge]).to include(callback_block)
        expect(events[:before_blueprint]).to include(callback_block)
        expect(events[:before_each]).to include(callback_block)
      end
    end

    context "when attaching multiple callbacks to the same event" do
      let(:second_callback) { proc { |context| "second callback" } }

      before do
        configuration.register_callback(:second_callback, &second_callback)
      end

      it "is expected to maintain registration order" do
        configuration.before(:each, :my_callback)
        configuration.before(:each, :second_callback)

        events = configuration.instance_variable_get(:@events)
        expect(events[:before_each]).to eq([callback_block, second_callback])
      end
    end
  end

  describe "#after" do
    let(:callback_block) { proc { |context| "after hook" } }

    before do
      configuration.register_callback(:my_callback, &callback_block)
    end

    it "is expected to attach a callback to an after event" do
      configuration.after(:each, :my_callback)

      events = configuration.instance_variable_get(:@events)
      expect(events[:after_each]).to include(callback_block)
    end

    it "is expected to accept string callback names and convert to symbols" do
      configuration.after(:each, "my_callback")

      events = configuration.instance_variable_get(:@events)
      expect(events[:after_each]).to include(callback_block)
    end

    context "when using valid events" do
      it "is expected to accept :forge event" do
        configuration.after(:forge, :my_callback)

        events = configuration.instance_variable_get(:@events)
        expect(events[:after_forge]).to include(callback_block)
      end

      it "is expected to accept :blueprint event" do
        configuration.after(:blueprint, :my_callback)

        events = configuration.instance_variable_get(:@events)
        expect(events[:after_blueprint]).to include(callback_block)
      end

      it "is expected to accept :each event" do
        configuration.after(:each, :my_callback)

        events = configuration.instance_variable_get(:@events)
        expect(events[:after_each]).to include(callback_block)
      end
    end

    context "when the event is invalid" do
      it "is expected to raise an ArgumentError" do
        expect { configuration.after(:invalid, :my_callback) }.to raise_error(
          ArgumentError,
          /Invalid event.*Expected one of/
        )
      end
    end

    context "when the callback is not registered" do
      it "is expected to raise an ArgumentError" do
        expect { configuration.after(:each, :unregistered_callback) }.to raise_error(
          ArgumentError,
          /Invalid callback/
        )
      end
    end

    context "when attaching the same callback to multiple events" do
      it "is expected to allow the callback to be reused" do
        configuration.after(:forge, :my_callback)
        configuration.after(:blueprint, :my_callback)
        configuration.after(:each, :my_callback)

        events = configuration.instance_variable_get(:@events)
        expect(events[:after_forge]).to include(callback_block)
        expect(events[:after_blueprint]).to include(callback_block)
        expect(events[:after_each]).to include(callback_block)
      end
    end

    context "when attaching multiple callbacks to the same event" do
      let(:second_callback) { proc { |context| "second callback" } }

      before do
        configuration.register_callback(:second_callback, &second_callback)
      end

      it "is expected to maintain registration order" do
        configuration.after(:each, :my_callback)
        configuration.after(:each, :second_callback)

        events = configuration.instance_variable_get(:@events)
        expect(events[:after_each]).to eq([callback_block, second_callback])
      end
    end
  end

  describe "Factories" do
    subject(:factories) { described_class::Factories.new }

    it "is expected to have default values" do
      expect(factories.auto_discover).to be true
      expect(factories.paths).to eq([])
    end

    it "is expected to accept custom values" do
      custom_factories = described_class::Factories.new(
        auto_discover: false,
        paths: ["lib/factories"]
      )

      expect(custom_factories.auto_discover).to be false
      expect(custom_factories.paths).to eq(["lib/factories"])
    end

    it "is expected to have predicate methods" do
      expect(factories).to respond_to(:auto_discover?)
      expect(factories).to respond_to(:paths?)
    end

    it "is expected to convert to hash" do
      expect(factories.to_h).to eq(
        auto_discover: true,
        paths: []
      )
    end
  end
end
