# frozen_string_literal: true

RSpec.describe SpecForge::Forge::Debug do
  let(:step) do
    SpecForge::Step.new(
      name: "Debug step",
      debug: true,
      source: {file_name: "test.yml", line_number: 42}
    )
  end

  let(:display) { instance_double(SpecForge::Forge::Display, action: nil) }
  let(:forge) { instance_double(SpecForge::Forge, display: display) }

  subject(:action) { described_class.new(step) }

  describe "#initialize" do
    it "stores the step" do
      expect(action.step).to eq(step)
    end
  end

  describe "#run" do
    subject(:run) { action.run(forge) }

    let(:tracker) { {called: false} }

    before do
      t = tracker
      SpecForge.configure do |config|
        config.on_debug { t[:called] = true }
      end
    end

    it "displays the debug action" do
      run

      expect(display).to have_received(:action).with(
        :debug,
        "Debug breakpoint triggered",
        color: :yellow
      )
    end

    it "executes the configured debug callback" do
      run

      expect(tracker[:called]).to be(true)
    end
  end
end
