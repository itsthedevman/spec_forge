# frozen_string_literal: true

module SpecForge
  class Spec
    #
    # Represents a single test expectation within a spec
    #
    # An Expectation defines what should be tested for a specific API request,
    # including the expected status code and response structure.
    #
    # @example YAML representation
    #   - name: "Get user successfully"
    #     expect:
    #       status: 200
    #       json:
    #         name: kind_of.string
    #
    class Expectation < Data.define(
      :id, :name, :line_number,
      :debug, :store_as, :documentation, :constraints
    )
      #
      # @return [Boolean] True if debugging is enabled
      #
      attr_predicate :debug

      #
      # @return [Boolean] True if store_as is set
      #
      attr_predicate :store_as

      #
      # Creates a new expectation with constraints
      #
      # @param id [String] Unique identifier
      # @param name [String] Human-readable name
      # @param line_number [Integer] Line number in source
      # @param debug [Boolean] Whether to enable debugging
      # @param store_as [String] Unique Context::Store identifier
      # @param documentation [Boolean] Whether to include in documentation generation
      # @param expect [Hash] Expected constraints
      #
      # @return [Expectation] A new expectation instance
      #
      def initialize(id:, name:, line_number:, debug:, store_as:, expect:, documentation:)
        constraints = Constraint.new(**expect)

        super(id:, name:, line_number:, debug:, store_as:, documentation:, constraints:)
      end

      #
      # Converts the expectation to a hash representation
      #
      # @return [Hash] Hash representation
      #
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
