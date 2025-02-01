# frozen_string_literal: true

require_relative "adapters/httparty"

module SpecForge
  class HTTPClient
    class Adapter
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
