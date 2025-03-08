# frozen_string_literal: true

module SpecForge
  class Spec
    class Expectation < Data.define(:id, :name, :line_number, :debug, :constraints)
      attr_predicate :debug

      def initialize(id:, name:, line_number:, debug:, expect:)
        constraints = Constraint.new(**expect)

        super(id:, name:, line_number:, debug:, constraints:)
      end

      def to_h
        {
          name:,
          line_number:,
          debug:,
          expect: constraints.to_h
        }
      end
    end
  end
end

require_relative "expectation/constraint"
