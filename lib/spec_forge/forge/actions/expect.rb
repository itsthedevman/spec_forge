# frozen_string_literal: true

module SpecForge
  class Forge
    class Expect < Action
      def run(forge)
        step.expects.each do |expectation|
          forge.runner.build(forge, step, expectation)
        end

        _passed_examples, failed_examples = forge.runner.run
        return if failed_examples.size == 0

        raise Error::ExpectationFailure.new(failed_examples.first)
      end
    end
  end
end
