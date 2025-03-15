# frozen_string_literal: true

RSpec.describe SpecForge::Callbacks do
  describe ".register" do
    let(:name) { "testing" }

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
end
