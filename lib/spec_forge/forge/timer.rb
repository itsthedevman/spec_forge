# frozen_string_literal: true

module SpecForge
  class Forge
    #
    # Simple timer for tracking execution duration
    #
    # Used to measure how long a forge run takes from start to finish.
    #
    class Timer
      # @return [Time, nil] Time when the timer started
      attr_reader :started_at

      # @return [Time, nil] Time when the timer stopped
      attr_reader :stopped_at

      #
      # Creates a new timer in the reset state
      #
      # @return [Timer] A new timer instance
      #
      def initialize
        reset
      end

      #
      # Resets the timer to its initial state
      #
      # @return [Timer] self for chaining
      #
      def reset
        @started_at = nil
        @stopped_at = nil

        self
      end

      #
      # Starts the timer
      #
      # @return [Timer] self for chaining
      #
      def start
        reset

        @started_at ||= Time.current

        self
      end

      #
      # Stops the timer
      #
      # @return [Timer] self for chaining
      #
      def stop
        return self if @started_at.nil?

        @stopped_at ||= Time.current

        self
      end

      #
      # Returns whether the timer has been started
      #
      # @return [Boolean] True if the timer has been started
      #
      def started?
        !started_at.nil?
      end

      #
      # Returns whether the timer has been stopped
      #
      # @return [Boolean] True if the timer has been stopped
      #
      def stopped?
        !stopped_at.nil?
      end

      #
      # Returns the elapsed time in seconds
      #
      # @return [Float] Seconds elapsed since start (or 0 if not started)
      #
      def time_elapsed
        return 0 if started_at.nil?

        (stopped_at || Time.current) - started_at
      end
    end
  end
end
