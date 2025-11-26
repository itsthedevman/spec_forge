# frozen_string_literal: true

module SpecForge
  class CLI
    #
    # Command for running SpecForge tests with filtering options
    #
    # @example Running all specs
    #   spec_forge run
    #
    # @example Running specific file
    #   spec_forge run users
    #
    # @example Running specific spec
    #   spec_forge run users:create_user
    #
    # @example Running specific expectation
    #   spec_forge run users:create_user:"POST /users"
    #
    class Run < Command
      command_name "run"
      syntax "run [target]"

      # TODO: Update these
      # TODO: Add more examples
      # summary ""
      # description ""
      # example "spec_forge run", "Run all specs in spec_forge/blueprints/"

      option "--tags", "TODO"
      option "--skip-tags", "TODO"

      def call
        tags = parse_tags(options.tags)
        skip_tags = parse_tags(options.skip_tags)

        blueprints = Loader.load_blueprints(path:, tags:, skip_tags:)

        Forge.ignite.run(blueprints)
      end
    end
  end
end
