# frozen_string_literal: true

module SpecForge
  module HTTP
    class Client
      attr_reader :request

      def initialize(request)
        @request = request
        @adapter = Backend.new(request)
      end

      def call
        @adapter.public_send(
          request.http_verb,
          request.url,
          query: request.query.transform_values(&:resolve),
          body: request.body.transform_values(&:resolve)
        )
      end
    end
  end
end
