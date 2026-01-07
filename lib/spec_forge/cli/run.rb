# frozen_string_literal: true

module SpecForge
  class CLI
    #
    # Command for running SpecForge blueprints with filtering and output options
    #
    # Executes workflow blueprints with support for file filtering, tag-based
    # selection, and configurable verbosity levels for output detail.
    #
    # @example Running all blueprints
    #   spec_forge run
    #
    # @example Running specific blueprint
    #   spec_forge run users_workflow
    #
    # @example Running with tags
    #   spec_forge run --tags smoke
    #
    class Run < Command
      command_name "run"
      syntax "run [path] [options]"
      summary "Execute workflow blueprints with optional filtering"

      description <<~DESC
        Execute SpecForge workflow blueprints with flexible filtering options.

        Supports:
          • File/directory targeting for selective execution
          • Tag-based filtering to run specific test categories
          • Multiple verbosity levels for output detail
          • Tag exclusion to skip certain tests

        Verbosity Levels:
          (default)  - Minimal output, dots for progress
          --verbose  - Show all steps with detailed results
          --debug    - Add full request/response for failures
          --trace    - Show everything for all steps
      DESC

      example "run",
        "Runs all blueprints in spec_forge/blueprints/"

      example "run users_workflow",
        "Runs only the users_workflow.yml blueprint"

      example "run blueprints/integration/",
        "Runs all blueprints in the integration directory"

      example "run --tags smoke",
        "Runs all blueprints tagged with 'smoke'"

      example "run --tags smoke,auth --skip-tags slow",
        "Runs smoke and auth tests, excluding slow ones"

      example "run users_workflow --tags smoke --debug",
        "Runs users_workflow smoke tests with debug output"

      option "--tags=TAGS", "Run only steps with these tags (comma-separated)"
      option "--skip-tags=TAGS", "Skip steps with these tags (comma-separated)"
      option "--verbose", "Show detailed step execution (verbosity level 1)"
      option "--debug", "Show full request/response for failures (verbosity level 2)"
      option "--trace", "Show everything for all steps (verbosity level 3)"

      aliases :r

      #
      # Executes the workflow blueprints with specified filters and options
      #
      # @return [void]
      #
      def call
        path = determine_path
        tags = parse_tags(options.tags)
        skip_tags = parse_tags(options.skip_tags)
        verbosity_level = determine_verbosity_level

        blueprints = Loader.load_blueprints(path:, tags:, skip_tags:)

        if blueprints.empty?
          puts "No blueprints found matching the criteria."
          exit(0)
        end

        Forge.ignite.run(blueprints, verbosity_level:)
      end

      private

      #
      # Determines the path to run from command arguments
      #
      # @return [Pathname, nil] The path to execute, or nil for all blueprints
      #
      def determine_path
        return nil if arguments.empty?

        Pathname.new(arguments.first)
      end

      #
      # Parses comma-separated tags from a string
      #
      # @param tag_string [String, nil] Comma-separated tag string
      #
      # @return [Array<String>] Array of tag strings
      #
      def parse_tags(tag_string)
        return [] if tag_string.blank?

        tag_string.split(",").map(&:strip).reject(&:blank?)
      end

      #
      # Determines verbosity level from command options
      #
      # @return [Integer] Verbosity level (0-3)
      #
      def determine_verbosity_level
        return 3 if options.trace
        return 2 if options.debug
        return 1 if options.verbose
        0
      end
    end
  end
end
