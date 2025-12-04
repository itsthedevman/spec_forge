# frozen_string_literal: true

RSpec.describe SpecForge::Forge::Hooks do
  let(:step) do
    SpecForge::Step.new(
      name: "Step with hooks",
      source: {file_name: "test.yml", line_number: 10},
      hooks: [
        {
          before_file: {name: :setup_database, arguments: nil}
        },
        {
          after_file: {name: :cleanup, arguments: {force: true}}
        }
      ]
    )
  end

  let(:display) { instance_double(SpecForge::Forge::Display, action: nil) }
  let(:callbacks) { instance_double(SpecForge::Forge::Callbacks, register_event: nil) }

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

    it "displays each hook action" do
      run

      expect(display).to have_received(:action).with(
        :hook,
        "before_file: setup_database",
        color: :bright_magenta
      )

      expect(display).to have_received(:action).with(
        :hook,
        "after_file: cleanup",
        color: :bright_magenta
      )
    end

    it "registers each event with the callbacks" do
      run

      expect(callbacks).to have_received(:register_event).with(
        :before_file,
        callback_name: :setup_database,
        arguments: nil
      )

      expect(callbacks).to have_received(:register_event).with(
        :after_file,
        callback_name: :cleanup,
        arguments: {force: true}
      )
    end

    context "when hooks have no arguments" do
      let(:step) do
        SpecForge::Step.new(
          name: "Step with simple hook",
          source: {file_name: "test.yml", line_number: 10},
          hooks: [
            {before_each: {name: :simple_hook, arguments: nil}}
          ]
        )
      end

      it "registers with nil arguments" do
        run

        expect(callbacks).to have_received(:register_event).with(
          :before_each,
          callback_name: :simple_hook,
          arguments: nil
        )
      end
    end
  end
end
