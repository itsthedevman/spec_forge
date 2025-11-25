# frozen_string_literal: true

module SpecForge
  class Blueprint < Data.define(:base_path, :file_path, :file_name, :name, :steps)
    def initialize(base_path:, file_path:, name:, steps: [])
      base_path = base_path.dirname if base_path.file?
      file_name = file_path.basename.to_s

      steps = steps.map { |s| Step.new(**s) }

      super(base_path:, file_path:, file_name:, name:, steps:,)
    end
  end
end
