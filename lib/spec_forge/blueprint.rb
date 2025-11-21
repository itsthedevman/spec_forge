# frozen_string_literal: true

module SpecForge
  class Blueprint < Data.define(:base_path, :file_path, :file_name, :steps)
    def initialize(base_path:, file_path:, steps: [])
      base_path = base_path.dirname if base_path.file?

      relative_path = file_path.relative_path_from(base_path)
      file_name = relative_path.to_s

      steps = steps.map { |s| Step.new(**s) }

      super(base_path:, file_path:, file_name:, steps:)
    end
  end
end
