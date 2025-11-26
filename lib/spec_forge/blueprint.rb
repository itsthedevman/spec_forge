# frozen_string_literal: true

module SpecForge
  class Blueprint < Data.define(:file_path, :file_name, :name, :steps)
    def initialize(file_path:, name:, steps: [])
      file_name = file_path.basename.to_s
      steps = steps.map { |s| Step.new(**s) }

      super(file_path:, file_name:, name:, steps:,)
    end
  end
end
