# frozen_string_literal: true

require_relative "http_client/adapter"

module SpecForge
  class HTTPClient
    attr_reader :request

    def initialize(request)
      @request = request

      base_url = request.base_url
      content_type = request.content_type

      @adapter = Adapter::HTTParty.new(base_url:, content_type:)
    end

    def call
      @adapter.public_send(
        request.http_verb,
        request.url,
        query: request.query.transform_values(&:result),
        body: request.body.transform_values(&:result)
      )
    end
  end
end
