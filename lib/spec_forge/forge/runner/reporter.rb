# frozen_string_literal: true

module SpecForge
  class Forge
    class Runner
      #
      # RSpec formatter listener for tracking test results
      #
      # Receives notifications from RSpec when examples pass or fail,
      # updating the forge's statistics and display accordingly.
      #
      class Reporter
        #
        # Creates a new reporter for the given forge instance
        #
        # @param forge [Forge, nil] The forge instance to report to
        #
        # @return [Reporter] A new reporter instance
        #
        def initialize(forge = nil)
          @forge = forge
          @stats = forge&.stats
          @display = forge&.display
        end

        #
        # Called when an RSpec example fails
        #
        # @param notification [RSpec::Core::Notifications::ExampleNotification] The failure notification
        #
        # @return [void]
        #
        def example_failed(notification)
          return if @stats.nil? || @display.nil?

          @stats[:failed] += 1
          @display.expectation_failed(notification.example.description, indent: 1)
        end

        #
        # Called when an RSpec example passes
        #
        # @param notification [RSpec::Core::Notifications::ExampleNotification] The success notification
        #
        # @return [void]
        #
        def example_passed(notification)
          return if @stats.nil? || @display.nil?

          @stats[:passed] += 1
          @display.expectation_passed(notification.example.description, indent: 1)
        end
      end
    end
  end
end
