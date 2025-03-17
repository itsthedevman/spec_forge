# frozen_string_literal: true

RSpec.describe SpecForge::Callbacks do
  let(:name) { "testing" }

  describe ".register" do
    subject(:registered) { described_class.register(name) {} }

    context "when the callback has not been registered" do
      it "is expected to store the block" do
        expect(registered).to be_kind_of(Proc)
      end
    end

    context "when the callback has already been registered" do
      it "is expected to print a warning" do
        registered

        expect {
          described_class.register(name) {}
        }.to output(
          "Callback #{name.in_quotes} is already registered. It will be overwritten\n"
        ).to_stderr
      end
    end

    context "when the callback is not provided a block" do
      it do
        expect {
          described_class.register(name)
        }.to raise_error(ArgumentError, "A block must be provided")
      end
    end
  end

  describe "#registered?" do
    subject(:registered?) { described_class.registered?(name) }

    context "when the callback has been registered" do
      before do
        described_class.register(name) {}
      end

      it { is_expected.to be(true) }
    end

    context "when the callback has not been registered" do
      it { is_expected.to be(false) }
    end
  end

  describe "#registered_names" do
    subject(:registered_names) { described_class.registered_names }

    context "when there are callbacks" do
      before do
        described_class.register(name) {}
      end

      it "is expected to return the names as an array" do
        is_expected.to eq([name])
      end
    end

    context "when there are no callbacks" do
      it "is expected to return an empty array" do
        is_expected.to eq([])
      end
    end
  end

  describe "#run_callbacks" do
    context "when the callback is defined" do
      it "is expected to call"
    end

    context "when the callback is not defined" do
      it {}
    end
  end
end
