# frozen_string_literal: true

module SpecForge
  class Spec
    class HTTPMethod < Data.define(:verb)
      class Delete < HTTPMethod
        def initialize = super(verb: "DELETE")
      end

      class Get < HTTPMethod
        def initialize = super(verb: "GET")
      end

      class Patch < HTTPMethod
        def initialize = super(verb: "PATCH")
      end

      class Post < HTTPMethod
        def initialize = super(verb: "POST")
      end

      class Put < HTTPMethod
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
      # Retrieves the corresponding HTTPMethod instance based on the provided HTTP verb
      #
      # @param verb [String, Symbol] The HTTP verb to look up (case-insensitive)
      #
      # @return [HTTPMethod, nil] The corresponding HTTPMethod instance, or nil if not found
      #
      def self.from(verb)
        METHODS[verb.downcase]
      end

      #
      # Returns if this HTTPMethod is a DELETE
      #
      # @return [Boolean]
      #
      def delete?
        verb == "DELETE"
      end

      #
      # Returns if this HTTPMethod is a GET
      #
      # @return [Boolean]
      #
      def get?
        verb == "GET"
      end

      #
      # Returns if this HTTPMethod is a PATCH
      #
      # @return [Boolean]
      #
      def patch?
        verb == "PATCH"
      end

      #
      # Returns if this HTTPMethod is a POST
      #
      # @return [Boolean]
      #
      def post?
        verb == "POST"
      end

      #
      # Returns if this HTTPMethod is a PUT
      #
      # @return [Boolean]
      #
      def put?
        verb == "PUT"
      end
    end
  end
end
