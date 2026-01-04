# frozen_string_literal: true

module SpecForge
  class Forge
    class Expect < Action
      def run(forge)
        show_expectation_count = step.expects.size > 1

        failed_examples =
          step.expects.flat_map.with_index do |expectation, index|
            failed = forge.runner.run(forge, step, expectation)

            forge.display.expectation_finished(
              failed_examples: failed,
              total_count: expectation.size,
              index: index + 1,
              show_index: show_expectation_count
            )

            failed
          end

        return if failed_examples.empty?

        raise Error::ExpectationFailure.new(failed_examples)
      end
    end
  end
end
