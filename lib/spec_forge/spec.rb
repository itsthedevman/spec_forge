# frozen_string_literal: true

module SpecForge
  class Spec
    attr_predicate :debug

    attr_reader :id, :name, :file_path, :file_name, :debug, :line_number
    attr_accessor :expectations

    def initialize(id:, name:, file_path:, file_name:, debug:, line_number:, expectations:)
      @id = id
      @name = name
      @file_path = file_path
      @file_name = file_name
      @debug = debug
      @line_number = line_number
      @expectations = expectations.map { |e| Expectation.new(**e) }
    end

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
