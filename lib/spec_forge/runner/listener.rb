# frozen_string_literal: true

module SpecForge
  class Runner
    #
    # Listens for RSpec test result notifications and triggers the appropriate callbacks
    #
    # This singleton class receives notifications from RSpec when examples pass or fail,
    # retrieves the current test context, and triggers the appropriate SpecForge callbacks.
    # It acts as a bridge between RSpec's notification system and SpecForge's callback system.
    #
    class Listener
      include Singleton

      #
      # Handles RSpec notifications for passing examples
      #
      # @param notification [RSpec::Core::Notifications::ExampleNotification]
      #   The notification object
      #
      def example_passed(notification)
        trigger_callback
      end

      #
      # Handles RSpec notifications for failing examples
      #
      # @param notification [RSpec::Core::Notifications::FailedExampleNotification]
      #   The notification object
      #
      def example_failed(notification)
        trigger_callback
      end

      private

      #
      # Triggers the appropriate SpecForge callback with the complete context
      #
      # Retrieves the current example context stored during the RSpec execution, and passes
      # everything to the appropriate callback.
      #
      # @private
      #
      def trigger_callback
        context = Runner::State.current.to_h.slice(
          :forge, :spec, :expectation, :example_group, :example
        )

        Runner::Callbacks.after_expectation(*context.values)
      end
    end
  end
end
