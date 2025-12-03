# frozen_string_literal: true

module SpecForge
  class Forge
    class Action
      attr_reader :step

      def initialize(step)
        @step = step
      end

      def run(_forge)
        raise "not implemented"
      end
    end
  end
end
