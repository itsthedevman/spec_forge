# frozen_string_literal: true

module SpecForge
  #
  # HTTP module providing request and response handling for API testing
  #
  # This module contains the HTTP client, request object, and other components
  # needed to make API calls and validate responses against expectations.
  #
  module HTTP
  end
end

require_relative "http/backend"
require_relative "http/client"
require_relative "http/verb"
require_relative "http/request"
