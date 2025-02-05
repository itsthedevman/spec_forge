# frozen_string_literal: true

module SpecForge
  module HTTP
    class Verb < Data.define(:name)
      class Delete < Verb
        def initialize = super(name: "DELETE")
      end

      class Get < Verb
        def initialize = super(name: "GET")
      end

      class Patch < Verb
        def initialize = super(name: "PATCH")
      end

      class Post < Verb
        def initialize = super(name: "POST")
      end

      class Put < Verb
        def initialize = super(name: "PUT")
      end

      DELETE = Delete.new
      GET = Get.new
      PATCH = Patch.new
      POST = Post.new
      PUT = Put.new

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
