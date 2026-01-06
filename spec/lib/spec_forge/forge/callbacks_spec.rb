# frozen_string_literal: true

RSpec.describe SpecForge::Forge::Callbacks do
  subject(:callbacks) { described_class.new }

  describe "#register" do
    it "registers a callback" do
      callbacks.register(:test) { "result" }
      expect(callbacks.registered?(:test)).to be true
    end

    it "raises ArgumentError when no block is given" do
      expect { callbacks.register(:test) }.to raise_error(ArgumentError, "A block must be provided")
    end

    context "when callback is already registered" do
      before do
        callbacks.register(:duplicate) { "first" }
      end

      it "warns and overwrites the callback" do
        expect {
          callbacks.register(:duplicate) { "second" }
        }.to output(/Callback "duplicate" is already registered/).to_stderr

        result = callbacks.run(:duplicate)
        expect(result).to eq("second")
      end
    end
  end

  describe "#registered?" do
    it "returns false for unregistered callbacks" do
      expect(callbacks.registered?(:unknown)).to be false
    end

    it "returns true for registered callbacks" do
      callbacks.register(:known) {}
      expect(callbacks.registered?(:known)).to be true
    end

    it "converts string names to symbols" do
      callbacks.register(:sym_callback) {}
      expect(callbacks.registered?("sym_callback")).to be true
    end
  end

  describe "#run" do
    it "executes the registered callback" do
      callbacks.register(:greet) { |name| "Hello, #{name}!" }
      result = callbacks.run(:greet, "World")
      expect(result).to eq("Hello, World!")
    end

    it "passes multiple arguments to the callback" do
      callbacks.register(:add) { |a, b, c| a + b + c }
      result = callbacks.run(:add, 1, 2, 3)
      expect(result).to eq(6)
    end

    it "raises UndefinedCallbackError for unregistered callbacks" do
      callbacks.register(:existing) {}

      expect {
        callbacks.run(:missing)
      }.to raise_error(SpecForge::Error::UndefinedCallbackError) do |error|
        expect(error.message).to include('"missing"')
        expect(error.message).to include('"existing"')
      end
    end
  end
end
