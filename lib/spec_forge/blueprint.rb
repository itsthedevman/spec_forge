# frozen_string_literal: true

module SpecForge
  class Blueprint
    def initialize(base_path:, file_path:, steps: [])
      @file_path = path
      @relative_path = Pathname.new(file_path).relative_path_from(base_path)
      @file_name = @relative_path.basename(".yml").to_s
      @steps = steps.map { |s| Step.new(**s) }
    end
  end
end
