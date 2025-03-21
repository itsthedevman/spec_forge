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

          # Clear the store for this file
          SpecForge.context.store.clear

          # Start fresh
          State.clear

          # Run the user's before_file callbacks
          run_user_callbacks(:before_file, file_context(forge))
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

          # Clear any "spec" level stored data
          SpecForge.context.store.clear_specs

          # Run the user's before_spec callbacks
          run_user_callbacks(:before_spec, spec_context(forge, spec))
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
        # @param example_group [RSpec::Core::ExampleGroup] The current running example group
        # @param example [RSpec::Core::Example] The current example
        #
        def before_expectation(forge, spec, expectation, example_group, example)
          # Store metadata to failure/error messages display the correct information
          Metadata.set_for_example(spec, expectation)

          # Store state data for callbacks and persisting data into the store
          State.set(
            forge:, spec:, expectation:, example_group:, example:,
            request: example_group.request
          )

          # Load the variable overlay for this expectation (if one exists)
          SpecForge.context.variables.use_overlay(expectation.id)

          # Run the user's before_each callbacks
          run_user_callbacks(:before_each, expectation_context(forge, spec, expectation, example))
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
        # @param example_group [RSpec::Core::ExampleGroup] The current running example group
        #
        def on_debug(forge, spec, expectation, example_group)
          DebugProxy.new(forge, spec, expectation, example_group).call
        end

        #
        # Callback executed after each expectation is run
        #
        # Performs cleanup and stores results if needed for future reference.
        #
        # @param forge [SpecForge::Forge] The forge being tested
        # @param spec [SpecForge::Spec] The spec being tested
        # @param expectation [SpecForge::Spec::Expectation] The expectation that was evaluated
        # @param example_group [RSpec::Core::ExampleGroup] The current running example group
        # @param example [RSpec::Core::Example] The current example
        #
        def after_expectation(forge, spec, expectation, example_group, example)
          # Note: Let variables on `example_group` have been reset by RSpec at this point.
          # Calling them will result in a new value being returned and memoized.
          # In other words, do not call `example_group.response` in here unless you
          # like potentially duplicating data ;)
          State.persist

          # Run the user's after_each callbacks
          run_user_callbacks(:after_each, expectation_context(forge, spec, expectation, example))

          # Clear the state for the next expectation
          State.clear
        end

        #
        # Callback executed after each spec is ran
        #
        # @param forge [SpecForge::Forge] The forge being tested
        # @param spec [SpecForge::Spec] The spec that was executed
        #
        def after_spec(forge, spec)
          # Run the user's after_spec callbacks
          run_user_callbacks(:after_spec, spec_context(forge, spec))
        end

        #
        # Callback executed after a file's specs have been ran
        #
        # @param forge [SpecForge::Forge] The forge representing the current file
        #
        def after_file(forge)
          # Run the user's after_file callbacks
          run_user_callbacks(:after_file, file_context(forge))
        end

        private

        #
        # Executes user-defined callbacks for a specific lifecycle point
        #
        # Processes the callback_type to extract timing and scope information,
        # adds this metadata to the context, and then triggers all registered
        # callbacks for that type.
        #
        # @param callback_type [Symbol, String] The type of callback to run
        #   (:before_file, :after_spec, etc.)
        # @param context [Hash] Context data containing state information for the callback
        #
        # @private
        #
        def run_user_callbacks(callback_type, context)
          callback_timing, callback_scope = callback_type.to_s.split("_")

          # Adds "before_each", "before", and "each" into the context so callbacks
          # can build logic off of them
          context.merge!(
            callback_type: callback_type.to_s,
            callback_timing:, callback_scope:
          )

          # Run the callbacks for this type
          SpecForge.context.global.callbacks.run(callback_type, context)
        end

        #
        # Builds the base context for file-level callbacks
        #
        # @param forge [SpecForge::Forge] The forge representing the file
        #
        # @return [Hash] Basic file context
        #
        # @private
        #
        def file_context(forge)
          {
            forge: forge,
            file_path: forge.metadata[:file_path],
            file_name: forge.metadata[:file_name]
          }
        end

        #
        # Builds context for spec-level callbacks
        # Includes file context plus spec information
        #
        # @param forge [SpecForge::Forge] The forge representing the file
        # @param spec [SpecForge::Spec] The spec being executed
        #
        # @return [Hash] Context with file and spec information
        #
        # @private
        #
        def spec_context(forge, spec)
          file_context(forge).merge(
            spec: spec,
            spec_name: spec.name,
            variables: SpecForge.context.variables
          )
        end

        #
        # Builds context for expectation-level callbacks
        # Includes spec context plus expectation information
        #
        # @param forge [SpecForge::Forge] The forge being tested
        # @param spec [SpecForge::Spec] The spec being tested
        # @param expectation [SpecForge::Spec::Expectation] The expectation being evaluated
        # @param example [RSpec::Core::Example] The current example
        #
        # @return [Hash] Context with file, spec and expectation information
        #
        # @private
        #
        def expectation_context(forge, spec, expectation, example)
          example_group = State.current.example_group

          # Pull this data from the State instead of example group to avoid creating a new value
          request = State.current.request
          response = State.current.response

          spec_context(forge, spec).merge(
            expectation:,
            expectation_name: expectation.name,
            request:,
            response:,
            example_group:,
            example:
          )
        end
      end
    end
  end
end
