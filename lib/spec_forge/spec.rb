# frozen_string_literal: true

module SpecForge
  #
  # Represents a test specification in SpecForge
  #
  # A Spec contains one or more Expectations and defines the base configuration
  # for those expectations. It maps directly to a test defined in YAML.
  #
  # @example YAML representation
  #   get_users:
  #     path: /users
  #     expectations:
  #     - expect:
  #         status: 200
  #
  class Spec < Data.define(
    :id, :name, :file_path, :file_name, :line_number,
    :debug, :documentation, :expectations
  )
    #
    # @return [Boolean] True if debugging is enabled
    #
    attr_predicate :debug

    #
    # Creates a new spec instance
    #
    # @param id [String] Unique identifier
    # @param name [String] Human-readable name
    # @param file_path [String] Absolute path to source file
    # @param file_name [String] Base name of file
    # @param debug [Boolean] Whether to enable debugging
    # @param line_number [Integer] Line number in source
    # @param documentation [Boolean] Whether to include in documentation generation
    # @param expectations [Array<Hash>] Expectation configurations
    #
    # @return [Spec] A new spec instance
    #
    def initialize(
      id:, name:, file_path:, file_name:, line_number:,
      debug:, documentation:, expectations:
    )
      expectations = expectations.map { |e| Expectation.new(**e) }

      super
    end

    #
    # Converts the spec to a hash representation
    #
    # @return [Hash] Hash representation
    #
    def to_h
      {
        name:,
        file_path:,
        file_name:,
        debug:,
        line_number:,
        documentation:,
        expectations: expectations.map(&:to_h)
      }
    end
  end
end

require_relative "spec/expectation"
