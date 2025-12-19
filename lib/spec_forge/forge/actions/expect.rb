# frozen_string_literal: true

module SpecForge
  class Forge
    class Expect < Action
      def run(forge)
        step.expects.each do |expectation|
          forge.runner.build(forge, step, expectation)
        end

        exit_code = forge.runner.run
      end
    end
  end
end
