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
      def extract_filter(input)
        spec_filter = input.gsub("::", ":") # Handles some edge cases

        # Note: Only split 3 because the expectation name can have colons in them.
        file_name, spec_name, expectation_name = spec_filter.split(":").map(&:strip)

        # Remove the quotes
        expectation_name.gsub!(/^['"]|['"]$/, "") if expectation_name.present?

        {file_name:, spec_name:, expectation_name:}
      end
    end
  end
end
