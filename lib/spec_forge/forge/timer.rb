# frozen_string_literal: true

module SpecForge
  class Forge
    class Timer
      attr_reader :started_at, :stopped_at

      def initialize
        reset
      end

      def reset
        @started_at = nil
        @stopped_at = nil

        self
      end

      def start
        reset

        @started_at ||= Time.current

        self
      end

      def stop
        return self if @started_at.nil?

        @stopped_at ||= Time.current

        self
      end

      def started?
        !started_at.nil?
      end

      def stopped?
        !stopped_at.nil?
      end

      def time_elapsed
        return 0 if started_at.nil?

        (stopped_at || Time.current) - started_at
      end
    end
  end
end
