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
      # summary "Execute your API tests with smart filtering options"
      # description ""
      # example "spec_forge run", "Run all specs in spec_forge/blueprints/"

      argument "PATH"
      option "--tags", "TODO"
      option "--skip-tags", "TODO"

      def call
        tags = parse_tags(options.tags)
        skip_tags = parse_tags(options.skip_tags)

        loader = SpecForge::Loader.new(path:, tags:, skip_tags:)
      end
    end
  end
end
