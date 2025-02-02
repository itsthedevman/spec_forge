# frozen_string_literal: true

require_relative "http_client/adapter"

module SpecForge
  class HTTPClient
    attr_reader :request

    def initialize(request)
      @request = request
      # @adapter = HTTParty.new
    end

    def call
    end
  end
end
