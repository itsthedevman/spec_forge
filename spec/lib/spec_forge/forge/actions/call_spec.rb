# frozen_string_literal: true

RSpec.describe SpecForge::Forge::Call do
  let(:step) do
    SpecForge::Step.new(
      name: "Step with call",
      source: {file_name: "test.yml", line_number: 5},
      call: {name: :my_callback, arguments: {key: "value"}}
    )
  end

  let(:display) { instance_double(SpecForge::Forge::Display, action: nil) }
  let(:callbacks) { instance_double(SpecForge::Forge::Callbacks, run_callback: nil) }

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

    it "displays the call action" do
      run

      expect(display).to have_received(:action).with(
        :call,
        "Call: my_callback",
        color: :yellow,
        style: :dim
      )
    end

    it "runs the callback with the arguments" do
      run

      expect(callbacks).to have_received(:run_callback).with(:my_callback, {key: "value"})
    end

    context "when arguments are nil" do
      let(:step) do
        SpecForge::Step.new(
          name: "Step with simple callback",
          source: {file_name: "test.yml", line_number: 5},
          call: {name: :simple_callback, arguments: nil}
        )
      end

      it "runs the callback with nil arguments" do
        run

        expect(callbacks).to have_received(:run_callback).with(:simple_callback, nil)
      end
    end
  end
end
