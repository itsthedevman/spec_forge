# frozen_string_literal: true

module SpecForge
  class Context
    #
    # Manages global state and variables at the spec file level.
    #
    # The Global class provides access to variables that are defined at the global level
    # in a spec file and are accessible across all specs and expectations in a file.
    # Unlike regular variables, global variables do not support overlaying - they maintain
    # consistent values throughout test execution.
    #
    # @example Basic usage
    #   global = Global.new(variables: {api_version: "v2", environment: "test"})
    #
    #   global.variables[:api_version] #=> "v2"
    #   global.variables[:environment] #=> "test"
    #
    #   # Update global variables
    #   global.update(variables: {environment: "staging"})
    #   global.variables[:environment] #=> "staging"
    #
    class Global
      # @return [Context::Variables] The container for global variables
      attr_reader :variables

      #
      # Creates a new Global context instance
      #
      # @param variables [Hash<Symbol, Object>] A hash of variable names and values
      #
      # @return [Global] The new Global instance
      #
      def initialize(variables: {})
        @variables = Variables.new(base: variables)
      end

      #
      # Updates the global variables
      #
      # @param variables [Hash<Symbol, Object>] A hash of variable names and values
      #
      # @return [self]
      #
      def update(variables:)
        @variables.update(base: variables)
        self
      end

      #
      # Returns a hash representation of the global context
      #
      # @return [Hash]
      #
      def to_h
        {
          variables: variables.to_h
        }
      end
    end
  end
end
