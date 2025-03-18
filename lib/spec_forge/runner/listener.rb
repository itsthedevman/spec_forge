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
        example = notification.example
        trigger_callback(example)
      end

      #
      # Handles RSpec notifications for failing examples
      #
      # @param notification [RSpec::Core::Notifications::FailedExampleNotification]
      #   The notification object
      #
      def example_failed(notification)
        example = notification.example
        trigger_callback(example)
      end

      #
      # Triggers the appropriate SpecForge callback with the complete context
      #
      # Retrieves the current example context stored during the RSpec execution,
      # adds the example object, and passes everything to the appropriate callback.
      #
      # @param example [RSpec::Core::Example] The example that was run
      #
      # @private
      #
      def trigger_callback(example)
        # {forge:, spec:, expectation:, example_group:}
        context = Runner.current_example_context
        context[:example] = example

        Runner::Callbacks.after_expectation(*context.values)
      end
    end
  end
end
