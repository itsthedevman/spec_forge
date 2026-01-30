# frozen_string_literal: true

RSpec.describe SpecForge::Forge::Timer do
  subject(:timer) { described_class.new }

  describe "#initialize" do
    it "starts with nil timestamps" do
      expect(timer.started_at).to be_nil
      expect(timer.stopped_at).to be_nil
    end
  end

  describe "#start" do
    it "sets started_at to current time" do
      freeze_time = Time.current
      allow(Time).to receive(:current).and_return(freeze_time)

      timer.start

      expect(timer.started_at).to eq(freeze_time)
    end

    it "returns self for chaining" do
      expect(timer.start).to eq(timer)
    end

    it "resets stopped_at when called again" do
      timer.start
      timer.stop
      timer.start

      expect(timer.stopped_at).to be_nil
    end
  end

  describe "#stop" do
    context "when timer has been started" do
      before { timer.start }

      it "sets stopped_at to current time" do
        freeze_time = Time.current
        allow(Time).to receive(:current).and_return(freeze_time)

        timer.stop

        expect(timer.stopped_at).to eq(freeze_time)
      end

      it "returns self for chaining" do
        expect(timer.stop).to eq(timer)
      end
    end

    context "when timer has not been started" do
      it "does not set stopped_at" do
        timer.stop

        expect(timer.stopped_at).to be_nil
      end
    end
  end

  describe "#reset" do
    before do
      timer.start
      timer.stop
    end

    it "clears started_at" do
      timer.reset

      expect(timer.started_at).to be_nil
    end

    it "clears stopped_at" do
      timer.reset

      expect(timer.stopped_at).to be_nil
    end

    it "returns self for chaining" do
      expect(timer.reset).to eq(timer)
    end
  end

  describe "#started?" do
    it "returns false when not started" do
      expect(timer.started?).to be(false)
    end

    it "returns true when started" do
      timer.start

      expect(timer.started?).to be(true)
    end
  end

  describe "#stopped?" do
    it "returns false when not stopped" do
      expect(timer.stopped?).to be(false)
    end

    it "returns true when stopped" do
      timer.start
      timer.stop

      expect(timer.stopped?).to be(true)
    end
  end

  describe "#time_elapsed" do
    it "returns 0 when not started" do
      expect(timer.time_elapsed).to eq(0)
    end

    it "returns elapsed time when started and stopped" do
      start_time = Time.current
      end_time = start_time + 5.seconds

      allow(Time).to receive(:current).and_return(start_time)
      timer.start

      allow(Time).to receive(:current).and_return(end_time)
      timer.stop

      expect(timer.time_elapsed).to eq(5)
    end

    it "returns running time when started but not stopped" do
      start_time = Time.current
      current_time = start_time + 3.seconds

      allow(Time).to receive(:current).and_return(start_time)
      timer.start

      allow(Time).to receive(:current).and_return(current_time)

      expect(timer.time_elapsed).to eq(3)
    end
  end
end
