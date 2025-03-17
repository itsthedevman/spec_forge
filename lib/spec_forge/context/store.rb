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
      # Represents a single stored entry with request, variables, and response data
      #
      # Entries are immutable once created and contain a deep-frozen
      # snapshot of the test state at the time of storage.
      #
      # @example Accessing stored entry data
      #   entry = store["user_creation"]
      #   entry.status    # => 201
      #   entry.body.id   # => 42
      #
      class Entry < Data.define(:scope, :request, :variables, :response)
        #
        # Creates a new immutable store entry
        #
        # @param request [Hash] The HTTP request that was executed
        # @param variables [Hash] Variables from the test context
        # @param response [Hash] The HTTP response received
        # @param scope [Symbol] Scope of this entry, either :file or :spec
        #
        # @return [Entry] A new immutable entry instance
        #
        def initialize(request:, variables:, response:, scope: :file)
          request = request.deep_freeze
          variables = variables.deep_freeze
          response = response.deep_freeze

          super
        end

        #
        # Shorthand accessor for the HTTP status code
        #
        # @return [Integer] The response status code
        #
        def status = response.status

        #
        # Shorthand accessor for the response body
        #
        # @return [Hash, Array, String] The parsed response body
        #
        def body = response.body

        #
        # Shorthand accessor for the response headers
        #
        # @return [Hash] The response headers
        #
        def headers = response.headers
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
      # @return [Entry] The newly created entry
      #
      def set(id, **)
        @inner[id] = Entry.new(**)
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
        @inner
      end
    end
  end
end
