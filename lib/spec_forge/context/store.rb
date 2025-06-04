# frozen_string_literal: true

module SpecForge
  class Context
    #
    # Manages storage of API responses for use in subsequent tests
    #
    # This class provides a mechanism to store HTTP requests and responses
    # during test execution, allowing values to be referenced in later tests
    # through the `store.id.body.attribute` syntax.
    #
    # @example Storing and retrieving a response in specs
    #   # In one expectation:
    #   store_as: user_creation
    #
    #   # In a later test:
    #   query:
    #     id: store.user_creation.body.id
    #
    class Store
      #
      # Represents a stored entry containing arbitrary data from test execution
      #
      # Entries are created during test execution to store custom data that can be
      # accessed in subsequent tests. Unlike the original rigid Data structure, this
      # OpenStruct-based approach allows storing any key-value pairs, making it perfect
      # for complex test scenarios that need custom configuration, metadata, or
      # computed values.
      #
      # @example Storing custom configuration data
      #   SpecForge.context.store.set(
      #     "app_config",
      #     api_version: "v2.1",
      #     feature_flags: { advanced_search: true }
      #   )
      #
      # @example Accessing stored data in tests
      #   headers:
      #     X-API-Version: store.app_config.api_version
      #   query:
      #     search_enabled: store.app_config.feature_flags.advanced_search
      #
      class Entry < OpenStruct
        #
        # Creates a new store entry
        #
        # @param scope [Symbol] Scope of this entry, either :file or :spec
        #
        # @return [Entry] A new entry instance
        #
        def initialize(scope: :file, **)
          super
        end

        #
        # Returns all available methods that can be called
        #
        # @return [Array] The method names
        #
        def available_methods
          @table.keys
        end
      end

      #
      # Creates a new empty store
      #
      # @return [Store] A new store instance
      #
      def initialize
        @inner = {}
      end

      #
      # Retrieves a stored entry by ID
      #
      # @param id [String, Symbol] The identifier for the stored entry
      #
      # @return [Entry, nil] The stored entry or nil if not found
      #
      def [](id)
        @inner[id]
      end

      #
      # Returns the number of entries in the store
      #
      # @return [Integer] The count of stored entries
      #
      def size
        @inner.size
      end

      #
      # Stores an entry with the specified ID
      #
      # @param id [String, Symbol] The identifier to store the entry under
      #
      # @return [self]
      #
      def set(id, **)
        @inner[id] = Entry.new(**)

        self
      end

      #
      # Removes all entries from the store
      #
      def clear
        @inner.clear
      end

      #
      # Removes all spec entries from the store
      #
      def clear_specs
        @inner.delete_if { |_k, v| v.scope == :spec }
      end

      #
      # Returns a hash representation of store
      #
      # @return [Hash]
      #
      def to_h
        @inner.transform_values(&:to_h).deep_stringify_keys
      end
    end
  end
end
