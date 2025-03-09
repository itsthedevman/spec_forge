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
  class Spec
    #
    # @return [Boolean] True if debugging is enabled
    #
    attr_predicate :debug

    #
    # Unique identifier for this spec
    #
    # @return [String] The spec ID
    #
    attr_reader :id

    #
    # Human-readable name for this spec
    #
    # @return [String] The spec name
    #
    attr_reader :name

    #
    # Absolute path to the file containing this spec
    #
    # @return [String] The file path
    #
    attr_reader :file_path

    #
    # Base name of the file without path or extension
    #
    # @return [String] The file name
    #
    attr_reader :file_name

    #
    # Whether to enable debugging for this spec
    #
    # @return [Boolean] Debug flag
    #
    attr_reader :debug

    #
    # Line number in the source file where this spec is defined
    #
    # @return [Integer] The line number
    #
    attr_reader :line_number

    #
    # The expectations to test for this spec
    #
    # @return [Array<Expectation>] The expectations
    #
    attr_accessor :expectations

    #
    # Creates a new spec instance
    #
    # @param id [String] Unique identifier
    # @param name [String] Human-readable name
    # @param file_path [String] Absolute path to source file
    # @param file_name [String] Base name of file
    # @param debug [Boolean] Whether to enable debugging
    # @param line_number [Integer] Line number in source
    # @param expectations [Array<Hash>] Expectation configurations
    #
    # @return [Spec] A new spec instance
    #
    def initialize(id:, name:, file_path:, file_name:, debug:, line_number:, expectations:)
      @id = id
      @name = name
      @file_path = file_path
      @file_name = file_name
      @debug = debug
      @line_number = line_number
      @expectations = expectations.map { |e| Expectation.new(**e) }
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
        expectations: expectations.map(&:to_h)
      }
    end
  end
end

require_relative "spec/expectation"
