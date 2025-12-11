# frozen_string_literal: true

module SpecForge
  class Forge
    class Expect < Action
      def run(forge)
        step.expects.each do |expectation|
          forge.runner.build(forge, expectation)
        end

        forge.runner.run
      end
    end
  end
end
