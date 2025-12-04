# frozen_string_literal: true

module SpecForge
  module Forge
    class Request < Action
      def run(forge)
        # Build the request
        # Send into Client
        # Take response and store it alongside the request in forge.local_variables
        request = create_request_from_step
      end

      private

      # base_url
      # url
      # http_verb
      # headers
      # query
      # raw
      # json
      def create_request_from_step
        request = step.request

        SpecForge::HTTP::Request.new(
          url: request.url,
          http_verb: request.http_verb,
          content_type: request.content_type,
          headers: request.headers,
          query: request.query,
          body: request.body
        )
      end
    end
  end
end
