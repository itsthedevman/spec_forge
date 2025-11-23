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

    private

    def normalize_steps(steps)
      steps.map do |step|
        Normalizer.normalize!(step, using: :step)
      rescue => e
        raise Error::LoadStepError.new(e, step)
      end
    end

    def tag_steps(steps, parent_tags: [])
      steps.each do |step|
        step[:tags] = (parent_tags + step[:tags]).uniq
        tag_steps(step[:steps], parent_tags: step[:tags])
      end
    end
  end
end
