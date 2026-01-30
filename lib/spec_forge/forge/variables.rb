# frozen_string_literal: true

module SpecForge
  class Forge
    #
    # Hash-based storage for runtime variables
    #
    # Manages both static (global) variables that persist across blueprints
    # and dynamic variables that are cleared between blueprints. Static
    # variables are restored when clear is called.
    #
    class Variables < Hash
      #
      # Creates a new Variables hash with static and dynamic values
      #
      # @param static [Hash] Variables that persist across blueprint clears
      # @param dynamic [Hash] Variables that are cleared between blueprints
      #
      # @return [Variables] A new variables instance
      #
      def initialize(static: {}, dynamic: {})
        @static = static.deep_dup

        merge!(@static, dynamic.deep_dup)
      end

      #
      # Clears dynamic variables while preserving static ones
      #
      # @return [Variables] self
      #
      def clear
        super
        merge!(@static)
      end
    end
  end
end
