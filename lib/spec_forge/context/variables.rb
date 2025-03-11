# frozen_string_literal: true

module SpecForge
  class Context
    #
    # Manages variable resolution across different expectations in SpecForge tests.
    #
    # The Variables class handles two layers of variable definitions:
    #   - Base variables: The core set of variables defined at the spec level
    #   - Overlay variables: Additional variables defined at the expectation level
    #       that can override base variables with the same name.
    #
    # @example Basic usage
    #   variables = Variables.new(
    #     base: {user_id: 123, name: "Test User"},
    #     overlay: {
    #       "expectation_1": {name: "Override User"}
    #     }
    #   )
    #
    #   variables[:user_id] #=> 123
    #   variables[:name]    #=> "Test User"
    #
    #   variables.use_overlay("expectation_1")
    #   variables[:name]    #=> "Override User"
    #   variables[:user_id] #=> 123 (unchanged)
    #
    class Variables
      #
      # Creates a new Variables container with base and overlay definitions
      #
      # @param base [Hash] The base set of variables (typically defined at spec level)
      # @param overlay [Hash<String, Hash>] A hash of overlay variable sets keyed by ID
      #
      # @return [Variables]
      #
      def initialize(base: {}, overlay: {})
        set(base:, overlay:)
      end

      #
      # Access a variable by its name
      #
      # @param name [Symbol] The variable name to access
      #
      # @return [Object, nil] The value of the variable or nil if not found
      #
      def [](name)
        @active[name]
      end

      #
      # Returns the active variables
      #
      # @return [Hash]
      #
      def to_h
        @active
      end

      #
      # Sets the base and overlay variable hashes
      #
      # @param base [Hash] The new base variable hash
      # @param overlay [Hash<String, Hash>] The new overlay variable hashes
      #
      # @return [self]
      #
      def set(base:, overlay: {})
        @base = base
        @overlay = overlay
        @active = Attribute.from(base)

        self
      end

      #
      # Applies a specific overlay to the base variables
      # If the overlay doesn't exist or is empty, no changes are made.
      #
      # @param id [String] The ID of the overlay to apply
      #
      # @return [nil]
      #
      def use_overlay(id)
        overlay = @overlay[id]
        return if overlay.blank?

        @active = Attribute.from(@base.merge(overlay))
      end

      #
      # Resolves all active variables
      # This processes any Attribute objects and returns their resolved values
      #
      # @return [Hash] The hash of resolved variable values
      #
      def resolve
        @active.resolve
      end
    end
  end
end
