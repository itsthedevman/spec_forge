# frozen_string_literal: true

module SpecForge
  module HTTP
    class Client
      def initialize
        @backend = Backend.new
      end

      def perform(request)
        @backend.public_send(
          request.http_verb.downcase,
          base_url: request.base_url,
          url: request.url.delete_prefix("/"),
          headers: request.headers,
          query: request.query,
          body: request.body
        )
      end
    end
  end
end
