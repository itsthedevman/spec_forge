# frozen_string_literal: true

module SpecForge
  module HTTP
    class Backend
      def initialize(request)
        @connection = Faraday.new(
          url: request.base_url,
          params: request.query.resolve,
          headers: {
            "Content-Type" => request.content_type.to_s,
            request.authorization[:header] => request.authorization[:value]
          }
        )
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
