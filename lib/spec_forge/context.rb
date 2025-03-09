# frozen_string_literal: true

module SpecForge
  #
  # Core data structure that maintains context during test execution
  #
  # Context stores and provides access to global variables, metadata about
  # the current spec file, test variables, and shared state across specs.
  # It acts as a central repository for test data during execution.
  #
  # @example Accessing the current context
  #   SpecForge.context.variables[:user_id] #=> 123
  #
  class Context < Data.define(:global, :metadata, :store, :variables)
    #
    # Creates a new context with default values
    #
    # @param global [Hash] Global variables shared across all specs
    # @param metadata [Hash] Information about the current spec file
    # @param variables [Hash] Test variables specific to the current context
    #
    # @return [Context] A new context instance
    #
    def initialize(global: {}, metadata: {}, variables: {})
      super(
        global: Global.new(**global),
        metadata: Metadata.new(**metadata),
        store: Store.new,
        variables: Variables.new(**variables)
      )
    end
  end
end

require_relative "context/global"
require_relative "context/metadata"
require_relative "context/store"
require_relative "context/variables"
