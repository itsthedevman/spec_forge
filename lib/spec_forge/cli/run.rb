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

      summary "Execute your API tests with smart filtering options"

      description <<~DESC
        Execute API tests with filtering options.

        Target formats:
          • file_name - Run all specs in a file
          • file:spec - Run specific spec
          • file:spec:"expectation" - Run individual expectation

        Uses RSpec for execution with detailed error reporting.
      DESC

      example "spec_forge run",
        "Run all specs in spec_forge/specs/"

      example "spec_forge run users",
        "Run all specs in users.yml"

      example "spec_forge run users:create_user",
        "Run all expectations in the create_user spec"

      example "spec_forge run users:create_user:\"POST /users\"",
        "Run expectations matching POST /users"

      example "spec_forge run users:create_user:\"POST /users - Create Admin\"",
        "Run the specific expectation named \"Create Admin\""

      #
      # Loads and runs all specs, or a subset of specs based on the provided arguments
      #
      def call
        return SpecForge.run if arguments.blank?

        # spec_forge users:show_user
        filter = extract_filter(arguments.first)

        # Filter and run the specs
        SpecForge.run(**filter)
      end

      private

      #
      # The input can be
      #
      #   "<file_name>" for a file
      #     Example: "users"
      #
      #   "<file_name>:<spec_name>" for a single spec
      #     Example: "users:show_user"
      #
      #   "<file_name:<spec_name>:'<verb> <path> - <?name>'" for a single expectation
      #     Example:
      #       "users:show_user:'GET /users/:id'"
      #     Example with name:
      #       "users:show_user:'GET /users/:id - Returns 404 due to missing user'"
      #
      # @private
      #
      def extract_filter(input)
        # Note: Only split 3 because the expectation name can have colons in them.
        file_name, spec_name, expectation_name = input.split(":", 3).map(&:strip)

        # Remove the quotes
        expectation_name.gsub!(/^['"]|['"]$/, "") if expectation_name.present?

        {file_name:, spec_name:, expectation_name:}
      end
    end
  end
end
