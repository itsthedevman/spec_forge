# frozen_string_literal: true

module SpecForge
  class Blueprint
    attr_reader :base_path, :file_path, :file_name, :name, :steps

    def initialize(base_path:, file_path:, name:, steps: [])
      base_path = base_path.dirname if base_path.file?
      @base_path = base_path

      @file_path = file_path
      @file_name = file_path.basename(".*")
      @name = name

      @steps = steps.map { |s| Step.new(**s) }
    end
  end
end
