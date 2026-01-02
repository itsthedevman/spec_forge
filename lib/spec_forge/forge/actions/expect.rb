# frozen_string_literal: true

module SpecForge
  class Forge
    class Expect < Action
      def run(forge)
        step.expects.each do |expectation|
          forge.runner.build(forge, step, expectation)
        end

        failed_examples = forge.runner.run(forge)
        return if failed_examples.empty?

        raise Error::ExpectationFailure.new(failed_examples)
      end
    end
  end
end
