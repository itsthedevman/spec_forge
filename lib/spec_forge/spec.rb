# frozen_string_literal: true

require_relative "spec/expectation"

module SpecForge
  class Spec < Data.define(:id, :name, :file_path, :file_name, :line_number, :expectations)
    attr_predicate :debug

    def initialize(id:, name:, file_path:, file_name:, line_number:, debug:, expectations:)
      expectations = expectations.map { |e| Expectation.new(e) }

      super
    end
  end
end
