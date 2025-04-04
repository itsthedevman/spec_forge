# frozen_string_literal: true

module SpecForge
  class Runner
    #
    # Maintains test execution state to prevent duplicate HTTP requests
    #
    # This singleton class captures and preserves references to the current test context,
    # including request and response objects that would otherwise be re-evaluated
    # when accessed after RSpec clears its memoized variables. It solves a specific
    # issue where accessing response data in after_expectation callbacks would
    # trigger duplicate HTTP requests.
    #
    class State < Struct.new(
      :forge, :spec, :expectation, :example_group, :example, :response, :request
    )
      include Singleton

      #
      # Returns the singleton instance representing the current test state
      #
      # @return [State] The current state instance
      #
      def self.current
        instance
      end

      #
      # Updates multiple attributes of the state at once
      #
      # @param attributes [Hash] A hash mapping attribute names to values
      #
      def self.set(attributes)
        attributes.each do |key, value|
          instance[key] = value
        end
      end

      #
      # Persists the current state to the context store if needed
      #
      # Only runs if the current expectation has a store_as directive
      #
      def self.persist
        return unless instance.expectation.store_as?

        instance.persist_to_store
      end

      #
      # Clears all state attributes
      #
      def self.clear
        instance.clear
      end

      ##########################################################################

      #
      # Clears all attributes in the state
      #
      def clear
        members.each { |key| self[key] = nil }
      end

      #
      # Persists the current test execution data to the context store
      #
      # Handles scope determination and stores request/response data
      # for later access via the store attribute
      #
      def persist_to_store
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
          request: request&.to_h,
          variables: SpecForge.context.variables.deep_dup,
          response: response&.to_hash
        )
      end
    end
  end
end
