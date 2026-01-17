# frozen_string_literal: true

RSpec.describe SpecForge::Forge::Call do
  let(:display) { instance_double(SpecForge::Forge::Display, action: nil) }
  let(:callbacks) { instance_double(SpecForge::Forge::Callbacks, run: nil) }

  let(:forge) do
    instance_double(
      SpecForge::Forge,
      display: display,
      callbacks: callbacks
    )
  end

  subject(:action) { described_class.new(step) }

  describe "#run" do
    subject(:run) { action.run(forge) }

    context "with positional arguments" do
      let(:step) do
        SpecForge::Step.new(
          name: "Step with positional args",
          source: {file_name: "test.yml", line_number: 5},
          calls: [{name: :my_callback, arguments: ["value1", "value2"]}]
        )
      end

      it "displays the call action" do
        run

        expect(display).to have_received(:action).with(
          "Call my_callback",
          symbol: :checkmark,
          symbol_styles: :yellow
        )
      end

      it "runs the callback with the context and positional arguments" do
        run

        expect(callbacks).to have_received(:run).with(:my_callback, anything, ["value1", "value2"])
      end
    end

    context "with keyword arguments" do
      let(:step) do
        SpecForge::Step.new(
          name: "Step with keyword args",
          source: {file_name: "test.yml", line_number: 5},
          calls: [{name: :my_callback, arguments: {key1: "value1", key2: "value2"}}]
        )
      end

      it "runs the callback with the context and keyword arguments" do
        run

        expect(callbacks).to have_received(:run).with(:my_callback, anything, {key1: "value1", key2: "value2"})
      end
    end

    context "when arguments are nil" do
      let(:step) do
        SpecForge::Step.new(
          name: "Step with no args",
          source: {file_name: "test.yml", line_number: 5},
          calls: [{name: :simple_callback, arguments: nil}]
        )
      end

      it "runs the callback with just the context" do
        run

        expect(callbacks).to have_received(:run).with(:simple_callback, anything, nil)
      end
    end

    context "with multiple callbacks" do
      let(:step) do
        SpecForge::Step.new(
          name: "Step with multiple calls",
          source: {file_name: "test.yml", line_number: 5},
          calls: [
            {name: :first_callback, arguments: nil},
            {name: :second_callback, arguments: {key: "value"}}
          ]
        )
      end

      it "runs all callbacks in order" do
        run

        expect(callbacks).to have_received(:run).with(:first_callback, anything, nil).ordered
        expect(callbacks).to have_received(:run).with(:second_callback, anything, {key: "value"}).ordered
      end

      it "displays each call action" do
        run

        expect(display).to have_received(:action).with(
          "Call first_callback",
          symbol: :checkmark,
          symbol_styles: :yellow
        )

        expect(display).to have_received(:action).with(
          "Call second_callback",
          symbol: :checkmark,
          symbol_styles: :yellow
        )
      end
    end
  end
end
