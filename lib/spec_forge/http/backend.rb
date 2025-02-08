# frozen_string_literal: true

module SpecForge
  module HTTP
    class Backend
      attr_reader :connection

      def initialize(request)
        @connection =
          Faraday.new(url: request.base_url) do |builder|
            # Authorization
            builder.headers[request.authorization.header] = request.authorization.value

            # Content-Type
            if request.content_type == "application/json"
              builder.request :json
              builder.response :json
            else
              builder.headers["Content-Type"] = request.content_type.to_s
            end

            # Params
            builder.params.merge!(request.query.resolve)
          end
      end

      def delete(url, query: {}, body: {})
        connection.delete(url) { |request| update_request(request, query, body) }
      end

      def get(url, query: {}, body: {})
        connection.get(url) { |request| update_request(request, query, body) }
      end

      def patch(url, query: {}, body: {})
        connection.patch(url) { |request| update_request(request, query, body) }
      end

      def post(url, query: {}, body: {})
        connection.post(url) { |request| update_request(request, query, body) }
      end

      def put(url, query: {}, body: {})
        connection.put(url) { |request| update_request(request, query, body) }
      end

      private

      def update_request(request, query, body)
        request.params.merge!(query)
        request.body = body.to_json
      end
    end
  end
end
