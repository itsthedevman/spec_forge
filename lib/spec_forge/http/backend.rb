# frozen_string_literal: true

module SpecForge
  module HTTP
    class Backend
      attr_reader :options

      def initialize(**options)
        @options = options
      end

      def delete(url, query: {}, body: {})
        raise "not implemented"
      end

      def get(url, query: {}, body: {})
        raise "not implemented"
      end

      def patch(url, query: {}, body: {})
        raise "not implemented"
      end

      def post(url, query: {}, body: {})
        raise "not implemented"
      end

      def put(url, query: {}, body: {})
        raise "not implemented"
      end
    end
  end
end
