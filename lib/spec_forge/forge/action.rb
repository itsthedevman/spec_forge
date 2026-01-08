# frozen_string_literal: true

module SpecForge
  class Forge
    #
    # Base class for step actions
    #
    # Actions are the executable units within a step. Each action type
    # (Call, Debug, Expect, Request, Store) inherits from this base class
    # and implements the run method to perform its specific behavior.
    #
    class Action
      # @return [Step] The step being executed
      attr_reader :step

      def initialize(step)
        @step = step
      end

      #
      # Executes the action
      #
      # @param _forge [Forge] The forge instance executing this action
      #
      # @return [void]
      #
      # @raise [RuntimeError] If not implemented by subclass
      #
      def run(_forge)
        raise "not implemented"
      end
    end
  end
end
