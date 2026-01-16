# frozen_string_literal: true

module SpecForge
  #
  # Represents a loaded blueprint containing a sequence of test steps
  #
  # A Blueprint is the runtime representation of a YAML blueprint file.
  # It contains metadata about the file and an ordered list of Step objects
  # ready for execution.
  #
  # @example
  #   blueprint = Blueprint.new(
  #     file_path: Pathname.new("spec_forge/blueprints/users.yml"),
  #     name: "users",
  #     steps: [{name: "Create user", request: {...}}]
  #   )
  #
  # TODO: Update docs for :hooks (blueprint-level hooks)
  class Blueprint < Data.define(:file_path, :file_name, :hooks, :name, :steps)
    def initialize(file_path:, name:, steps: [], hooks: {})
      file_name = file_path.basename.to_s
      steps = steps.map { |s| Step.new(**s) }
      hooks = Step::Call.wrap_hooks(hooks)

      super(file_path:, file_name:, hooks:, name:, steps:,)
    end
  end
end
