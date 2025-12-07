# frozen_string_literal: true

module SpecForge
  module HTTP
    class Client
      def initialize(base_url:)
        @backend = Backend.new(base_url:)
      end

      def perform(request)
        @backend.public_send(
          request.http_verb.to_s.downcase,
          request.url.delete_prefix("/"),
          headers: request.headers,
          query: request.query,
          body: request.body
        )
      end
    end
  end
end
