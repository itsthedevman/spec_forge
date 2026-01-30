# frozen_string_literal: true

module SpecForge
  class Forge
    #
    # Action for the `expect:` step attribute
    #
    # Runs expectations against the current response, validating status codes,
    # headers, and JSON body against expected values using RSpec matchers.
    #
    class Expect < Action
      #
      # Runs all expectations for the step against the current response
      #
      # @param forge [Forge] The forge instance containing response data
      #
      # @return [void]
      #
      # @raise [Error::ExpectationFailure] If any expectations fail
      #
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
