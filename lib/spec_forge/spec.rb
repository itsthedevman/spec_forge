# frozen_string_literal: true

require_relative "spec/expectation"

module SpecForge
  class Spec
    attr_predicate :debug

    attr_reader :name, :file_path, :file_name, :line_number, :expectations, :options

    def initialize(name:, file_path:, file_name:, line_number:, **input)
      @name = name
      @file_path = file_path
      @file_name = file_name
      @line_number = line_number

      # Don't pass this down to the expectations
      @debug = input.delete(:debug) || false
      @options = normalize_options(input)

      @expectations = input[:expectations].map { |e| Expectation.new(e) }
    end

    private

    def normalize_options(input)
      config = SpecForge.configuration.to_h.slice(:base_url, :headers, :query)
      Configuration.overlay_options(config, input.except(:expectations))
    end
  end
end
