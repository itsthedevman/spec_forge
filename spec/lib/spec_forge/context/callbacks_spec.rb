# frozen_string_literal: true

RSpec.describe SpecForge::Context::Callbacks do
  describe "#initialize" do
    let(:callbacks) { [] }

    subject(:context) { described_class.new(callbacks) }

    context "when callbacks are provided" do
      let(:callbacks) do
        [
          {before_each: "callback_1", after_each: "callback_2"},
          {before_spec: "callback_3", after_file: "callback_4"}
        ]
      end

      subject(:groups) { context.to_h }

      context "and there are no duplicates" do
        it "is expected to group them by their hook" do
          is_expected.to match(
            before_each: Set["callback_1"],
            after_each: Set["callback_2"],
            before_spec: Set["callback_3"],
            after_file: Set["callback_4"]
          )
        end
      end

      context "and there are duplicates" do
        before do
          callbacks << {before_each: "callback_1"}
        end

        it "is expected to ignore the duplicate" do
          is_expected.to match(
            before_each: Set["callback_1"],
            after_each: Set["callback_2"],
            before_spec: Set["callback_3"],
            after_file: Set["callback_4"]
          )
        end
      end

      context "and there are nil and empty strings" do
        let(:callbacks) do
          [{before_each: "", after_each: nil}]
        end

        it "is expected to ignore them" do
          is_expected.to eq({})
        end
      end
    end
  end
end
