# frozen_string_literal: true

module SpecForge
  class Spec
    class Expectation
      attr_reader :input, :status

      def initialize(input)
        @input = input
      end
    end
  end
end
