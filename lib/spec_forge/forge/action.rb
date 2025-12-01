# frozen_string_literal: true

module SpecForge
  class Forge
    class Action
      def initialize(step)
        @step = step
      end

      def run(_forge)
        raise "not implemented"
      end
    end
  end
end
