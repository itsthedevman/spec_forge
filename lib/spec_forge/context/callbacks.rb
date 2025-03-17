# frozen_string_literal: true

module SpecForge
  class Context
    #
    # Manages user-defined callbacks grouped by lifecycle hook
    #
    # This class collects and organizes callbacks by their hook type
    # (before_file, after_each, etc.) to support the test lifecycle.
    # It ensures callbacks are properly categorized for execution.
    #
    # @example Creating callback groups
    #   callbacks = Context::Callbacks.new([
    #     {before_file: "setup_environment"},
    #     {after_each: "log_test_result"}
    #   ])
    #
    class Callbacks
      #
      # Creates a new callbacks collection
      #
      # @param callback_array [Array] Optional initial callbacks to register
      #
      # @return [Callbacks] A new callbacks collection
      #
      def initialize(callback_array = [])
        set(callback_array)
      end

      #
      # Updates the callbacks collection
      #
      # @param callback_array [Array] New callbacks to register
      #
      # @return [self]
      #
      def set(callback_array)
        @inner = organize_callbacks_by_hook(callback_array)
        self
      end

      #
      # Returns the hash representation of callbacks
      #
      # @return [Hash] Callbacks organized by hook type
      #
      def to_h
        @inner
      end

      private

      #
      # Organizes callbacks from an array to hash structure by hook type
      # Groups callbacks like before_file, after_each, etc. for easier lookup
      #
      # @param callback_array [Array] The array of callbacks
      #
      # @return [Hash] Callbacks indexed by hook type
      #
      # @private
      #
      def organize_callbacks_by_hook(callback_array)
        groups = Hash.new { |h, k| h[k] = Set.new }

        callback_array.each_with_object(groups) do |callbacks, groups|
          callbacks.each do |hook, name|
            next if name.blank?

            groups[hook].add(name)
          end
        end
      end
    end
  end
end
