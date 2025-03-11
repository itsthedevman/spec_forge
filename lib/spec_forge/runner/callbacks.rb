# frozen_string_literal: true

module SpecForge
  class Runner
    #
    # Manages lifecycle hooks for test execution
    #
    # This class provides callback methods that run at specific points during test execution
    # to prepare the test environment, manage state, and perform cleanup operations. These
    # callbacks integrate with RSpec's test lifecycle and maintain the SpecForge context.
    #
    # @example Running before file callback
    #   Callbacks.before_file(forge)
    #
    class Callbacks
      class << self
        #
        # Callback executed before a file's specs are run
        #
        # Initializes global context and sets up any file-level state needed
        # for all specs in the file.
        #
        # @param forge [SpecForge::Forge] The forge representing the current file
        #
        def before_file(forge)
          # Set the global variables
          SpecForge.context.global.set(**forge.global)

          # And resolve them
          SpecForge.context.global.variables.resolve

          # Clear the store for this file
          SpecForge.context.store.clear
        end

        #
        # Callback executed before each spec is run
        #
        # Prepares the context for a specific spec, including loading
        # spec-level variables and configuration.
        #
        # @param forge [SpecForge::Forge] The forge being tested
        # @param spec [SpecForge::Spec] The spec about to be executed
        #
        def before_spec(forge, spec)
          # Prepare the variables for this spec
          SpecForge.context.variables.set(**forge.variables_for_spec(spec))

          # And resolve the spec level variables
          SpecForge.context.variables.resolve_base

          # Finally, clear spec level stores
          SpecForge.context.store.clear_specs
        end

        #
        # Callback executed before each expectation is run
        #
        # Prepares variables for the specific expectation and sets up
        # example metadata for error reporting.
        #
        # @param forge [SpecForge::Forge] The forge being tested
        # @param spec [SpecForge::Spec] The spec being tested
        # @param expectation [SpecForge::Spec::Expectation] The expectation about to be evaluated
        #
        def before_expectation(forge, spec, expectation)
          # Set metadata for this example
          Metadata.set_for_example(spec, expectation)

          # Load the variable overlay for this expectation (if one exists)
          SpecForge.context.variables.use_overlay(expectation.id)

          # Ensure everything is resolved
          SpecForge.context.variables.resolve
        end

        #
        # Callback executed after each expectation is run
        #
        # Performs cleanup and stores results if needed for future reference.
        #
        # @param forge [SpecForge::Forge] The forge being tested
        # @param spec [SpecForge::Spec] The spec being tested
        # @param expectation [SpecForge::Spec::Expectation] The expectation that was evaluated
        # @param example [RSpec::Core::Example] The current running example
        #
        def after_expectation(forge, spec, expectation, example)
          store_result(expectation, example.request, example.response) if expectation.store_as?
        end

        #
        # Handles debug mode for an expectation
        #
        # When debugging is enabled for a spec or expectation, this method
        # creates a debugging environment for inspecting test state.
        #
        # @param forge [SpecForge::Forge] The forge being tested
        # @param spec [SpecForge::Spec] The spec being tested
        # @param expectation [SpecForge::Spec::Expectation] The expectation being evaluated
        # @param example [RSpec::Core::Example] The current running example
        #
        def on_debug(forge, spec, expectation, example)
          DebugProxy.new(forge, spec, expectation, example).call
        end

        private

        #
        # Stores the result of an expectation for later reference
        #
        # This method processes and stores test execution data into the context store.
        # It handles scope determination (file vs. spec) based on prefixes in the ID,
        # and normalizes the ID by removing scope prefixes.
        #
        # @param expectation [SpecForge::Spec::Expectation] The expectation that is being stored
        # @param request [SpecForge::HTTP::Request] The HTTP request that was executed
        # @param response [Faraday::Response] The HTTP response received
        #
        def store_result(expectation, request, response)
          id = expectation.store_as
          scope = :file

          # Remove the file prefix if it was explicitly provided
          id = id.delete_prefix("file.") if id.start_with?("file.")

          # Change scope to spec if desired
          if id.start_with?("spec.")
            id = id.delete_prefix("spec.")
            scope = :spec
          end

          SpecForge.context.store.set(
            id,
            scope:,
            request: request.to_h,
            variables: SpecForge.context.variables.resolve,
            response: {
              headers: response.headers,
              status: response.status,
              body: response.body
            }
          )
        end
      end
    end
  end
end
