# frozen_string_literal: true

module SpecForge
  module HTTP
    class Method < Data.define(:verb)
      class Delete < Method
        def initialize = super(verb: "DELETE")
      end

      class Get < Method
        def initialize = super(verb: "GET")
      end

      class Patch < Method
        def initialize = super(verb: "PATCH")
      end

      class Post < Method
        def initialize = super(verb: "POST")
      end

      class Put < Method
        def initialize = super(verb: "PUT")
      end

      DELETE = Delete.new
      GET = Get.new
      PATCH = Patch.new
      POST = Post.new
      PUT = Put.new

      METHODS = {
        delete: DELETE,
        get: GET,
        patch: PATCH,
        post: POST,
        put: PUT
      }.with_indifferent_access.freeze

      #
      # Retrieves the corresponding Method instance based on the provided HTTP verb
      #
      # @param verb [String, Symbol] The HTTP verb to look up (case-insensitive)
      #
      # @return [Method, nil] The corresponding Method instance, or nil if not found
      #
      def self.from(verb)
        METHODS[verb.downcase]
      end

      #
      # Returns if this Method verb matches another Method's verb, or the verb
      # as a String or Symbol
      #
      # @param other [Object] The thing to check against this object
      #
      # @return [Boolean]
      #
      def ==(other)
        case other
        when Method
          verb == other.verb
        when String, Symbol
          self == self.class.from(other)
        else
          false
        end
      end

      #
      # Returns if this Method is a DELETE
      #
      # @return [Boolean]
      #
      def delete?
        verb == "DELETE"
      end

      #
      # Returns if this Method is a GET
      #
      # @return [Boolean]
      #
      def get?
        verb == "GET"
      end

      #
      # Returns if this Method is a PATCH
      #
      # @return [Boolean]
      #
      def patch?
        verb == "PATCH"
      end

      #
      # Returns if this Method is a POST
      #
      # @return [Boolean]
      #
      def post?
        verb == "POST"
      end

      #
      # Returns if this Method is a PUT
      #
      # @return [Boolean]
      #
      def put?
        verb == "PUT"
      end
    end
  end
end
