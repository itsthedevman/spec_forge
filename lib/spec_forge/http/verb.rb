# frozen_string_literal: true

module SpecForge
  module HTTP
    #
    # Represents an HTTP verb (method)
    #
    # This class provides a type-safe way to work with HTTP methods,
    # with predefined constants for common verbs like GET, POST, etc.
    #
    # @example Using predefined verbs
    #   HTTP::Verb::GET    # => #<HTTP::Verb::Get @name="GET">
    #   HTTP::Verb::POST   # => #<HTTP::Verb::Post @name="POST">
    #
    # @example Checking verb types
    #   verb = HTTP::Verb::POST
    #   verb.post?   # => true
    #   verb.get?    # => false
    #
    class Verb < Data.define(:name)
      #
      # Represents the HTTP DELETE method
      #
      # @return [Delete] A DELETE verb instance
      #
      class Delete < Verb
        def initialize = super(name: "DELETE")
      end

      #
      # Represents the HTTP GET method
      #
      # @return [Get] A GET verb instance
      #
      class Get < Verb
        def initialize = super(name: "GET")
      end

      #
      # Represents the HTTP PATCH method
      #
      # @return [Patch] A PATCH verb instance
      #
      class Patch < Verb
        def initialize = super(name: "PATCH")
      end

      #
      # Represents the HTTP POST method
      #
      # @return [Post] A POST verb instance
      #
      class Post < Verb
        def initialize = super(name: "POST")
      end

      #
      # Represents the HTTP PUT method
      #
      # @return [Put] A PUT verb instance
      #
      class Put < Verb
        def initialize = super(name: "PUT")
      end

      #
      # A predefined DELETE verb instance for HTTP method usage
      #
      # @return [Verb::Delete] A singleton instance representing the HTTP DELETE method
      # @see Verb
      #
      DELETE = Delete.new

      #
      # A predefined GET verb instance for HTTP method usage
      #
      # @return [Verb::Get] A singleton instance representing the HTTP GET method
      # @see Verb
      #
      GET = Get.new

      #
      # A predefined PATCH verb instance for HTTP method usage
      #
      # @return [Verb::Patch] A singleton instance representing the HTTP PATCH method
      # @see Verb
      #
      PATCH = Patch.new

      #
      # A predefined POST verb instance for HTTP method usage
      #
      # @return [Verb::Post] A singleton instance representing the HTTP POST method
      # @see Verb
      #
      POST = Post.new

      #
      # A predefined PUT verb instance for HTTP method usage
      #
      # @return [Verb::Put] A singleton instance representing the HTTP PUT method
      # @see Verb
      #
      PUT = Put.new

      #
      # All HTTP verbs as a lookup hash
      #
      # @return [Hash<Symbol, Verb>]
      #
      VERBS = {
        delete: DELETE,
        get: GET,
        patch: PATCH,
        post: POST,
        put: PUT
      }.freeze

      #
      # Retrieves the corresponding Verb instance based on the provided HTTP name
      #
      # @param name [String, Symbol] The HTTP name to look up (case-insensitive)
      #
      # @return [Verb, nil] The corresponding Verb instance, or nil if not found
      #
      def self.from(name)
        VERBS[name.downcase.to_sym]
      end

      #
      # Returns if this Verb name matches another Verb's name, or the name
      # as a String or Symbol
      #
      # @param other [Object] The thing to check against this object
      #
      # @return [Boolean]
      #
      def ==(other)
        case other
        when Verb
          name == other.name
        when String, Symbol
          self == self.class.from(other)
        else
          false
        end
      end

      alias_method :to_s, :name

      #
      # Returns if this Verb is a DELETE
      #
      # @return [Boolean]
      #
      def delete?
        name == "DELETE"
      end

      #
      # Returns if this Verb is a GET
      #
      # @return [Boolean]
      #
      def get?
        name == "GET"
      end

      #
      # Returns if this Verb is a PATCH
      #
      # @return [Boolean]
      #
      def patch?
        name == "PATCH"
      end

      #
      # Returns if this Verb is a POST
      #
      # @return [Boolean]
      #
      def post?
        name == "POST"
      end

      #
      # Returns if this Verb is a PUT
      #
      # @return [Boolean]
      #
      def put?
        name == "PUT"
      end
    end
  end
end
