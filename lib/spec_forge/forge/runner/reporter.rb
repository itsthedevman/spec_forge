# frozen_string_literal: true

module SpecForge
  class Forge
    class Runner
      class Reporter
        def initialize(forge = nil)
          @forge = forge
          @stats = forge&.stats
          @display = forge&.display
        end

        def example_failed(notification)
          return if @stats.nil? || @display.nil?

          @stats[:failed] += 1
          @display.expectation_failed(notification.example.description, indent: 1)
        end

        def example_passed(notification)
          return if @stats.nil? || @display.nil?

          @stats[:passed] += 1
          @display.expectation_passed(notification.example.description, indent: 1)
        end
      end
    end
  end
end
