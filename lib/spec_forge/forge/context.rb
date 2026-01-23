# frozen_string_literal: true

module SpecForge
  class Forge
    #
    # Immutable execution context passed to callbacks and hooks
    #
    # Contains the current state during forge execution including
    # variables, the current blueprint and step, and any error that occurred.
    #
    class Context < Data.define(:variables, :blueprint, :step, :error)
      def initialize(**context)
        context[:variables] ||= nil
        context[:blueprint] ||= nil
        context[:step] ||= nil
        context[:error] ||= nil

        super(context)
      end

      #
      # Returns whether the context represents a successful state
      #
      # @return [Boolean] True if no error is present
      #
      def success?
        error.nil?
      end

      #
      # Returns whether the context represents a failed state
      #
      # @return [Boolean] True if an error is present
      #
      def failure?
        !success?
      end
    end
  end
end
