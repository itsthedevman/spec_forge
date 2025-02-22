# frozen_string_literal: true

module SpecForge
  class CLI
    class Run < Command
      command_name "run"
      syntax "run"
      summary "Runs all specs"

      # option "-n", "--no-docs", "Do not generate OpenAPI documentation on completion"

      def call
        return SpecForge.run if arguments.blank?

        #
        # First argument can be:
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
        spec_filter = arguments.first.gsub("::", ":") # Handles some edge cases
        file_name, spec_name, expectation_name = spec_filter.split(":").map(&:strip)

        # Remove any quotes
        expectation_name.gsub!(/['"]+(.+)['"]+/, "\1") if expectation_name.present?

        # Filter and run the specs
        SpecForge.run(file_name:, spec_name:, expectation_name:)
      end
    end
  end
end
