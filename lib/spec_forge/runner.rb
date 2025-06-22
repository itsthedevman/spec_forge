# frozen_string_literal: true

module SpecForge
  #
  # Handles the execution of specs through RSpec
  # Converts SpecForge specs into RSpec examples and runs them
  #
  class Runner
    class << self
      #
      # Prepares forge objects for test execution
      #
      # Loads the forge helper, registers factories, loads specs from files,
      # applies filtering, and returns ready-to-run forge objects.
      #
      # @param file_name [String, nil] Optional file name filter
      # @param spec_name [String, nil] Optional spec name filter
      # @param expectation_name [String, nil] Optional expectation name filter
      #
      # @return [Array<Forge>] Array of prepared forge objects
      #
      def prepare(file_name: nil, spec_name: nil, expectation_name: nil)
        load_forge_helper

        # Load factories
        Factory.load_and_register

        # Load the specs from their files and create forges from them
        forges = Loader.load_from_files.map { |f| Forge.new(*f) }

        # Filter out the specs and expectations
        forges = Filter.apply(forges, file_name:, spec_name:, expectation_name:)

        # Tell the user that we filtered if we did
        Filter.announce(forges, file_name:, spec_name:, expectation_name:)

        forges
      end

      #
      # Runs the prepared forges through RSpec
      #
      # Sets up the RSpec adapter and executes all tests, with optional
      # exit behavior for CLI usage.
      #
      # @param forges [Array<Forge>] The forge objects to run
      # @param exit_on_finish [Boolean] Whether to exit the process when complete
      # @param exit_on_failure [Boolean] Whether to exit the process if any test fails
      #
      # @return [Integer, nil] Exit status if exit_on_finish is false
      #
      def run(forges, **)
        Adapter.setup(forges)
        Adapter.run(**)
      end

      private

      def load_forge_helper
        forge_helper = SpecForge.forge_path.join("forge_helper.rb")
        require_relative forge_helper if File.exist?(forge_helper)

        # Validate in case anything was changed
        SpecForge.configuration.validate
      end
    end
  end
end

require_relative "runner/adapter"
require_relative "runner/callbacks"
require_relative "runner/debug_proxy"
require_relative "runner/listener"
require_relative "runner/metadata"
require_relative "runner/state"
