# frozen_string_literal: true

module SpecForge
  class Context
    class Metadata < Context
      #
      # Makes getting/setting easier
      # @private
      #
      class Settable
        def initialize(inner)
          set(inner)
        end

        def set(inner)
          @inner = inner
        end

        def get
          @inner
        end
      end

      def initialize
        clear
      end

      def clear
        @base_url = Settable.new("")
        @url = Settable.new("")
        @http_method = Settable.new("")
        @headers = Settable.new({})
        @query = Settable.new({})
        @body = Settable.new({})
        @debug = Settable.new(false)
      end

      def store(namespace, *value)
        namespace = retrieve_namespace(namespace)
        namespace.set(value)
      end

      def retrieve(*path)
        namespace = retrieve_namespace(path.first)
        return namespace unless namespace.is_a?(Hash)

        namespace[path.second]
      end

      private

      def retrieve_namespace(name)
        case name.to_sym
        when :base_url
          @base_url
        when :url
          @url
        when :http_method
          @http_method
        when :debug
          @debug
        when :headers
          @headers
        when :query
          @query
        when :body
          @body
        else
          raise ArgumentError, "Invalid namespace for Metadata context. Got #{name}"
        end
      end
    end
  end
end
