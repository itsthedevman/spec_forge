# frozen_string_literal: true

require_relative "http_client/adapter"

module SpecForge
  class HTTPClient
    def initialize(request)
      @spec_request = request
      # @adapter = HTTParty.new
    end

    def call
    end
  end
end
