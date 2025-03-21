# frozen_string_literal: true

module SpecForge
  #
  # HTTP module providing request and response handling for API testing
  #
  # This module contains the HTTP client, request object, and other components
  # needed to make API calls and validate responses against expectations.
  #
  module HTTP
    #
    # A mapping of HTTP status codes to their standard descriptions
    #
    # This constant provides a lookup table of common HTTP status codes with their
    # official descriptions according to HTTP specifications. Used internally
    # to generate human-readable test output.
    #
    # @example Looking up a status code description
    #   HTTP::STATUS_DESCRIPTIONS[200] # => "OK"
    #   HTTP::STATUS_DESCRIPTIONS[404] # => "Not Found"
    #
    STATUS_DESCRIPTIONS = {
      # Success codes
      200 => "OK",
      201 => "Created",
      202 => "Accepted",
      204 => "No Content",

      # Redirection
      301 => "Moved Permanently",
      302 => "Found",
      304 => "Not Modified",
      307 => "Temporary Redirect",
      308 => "Permanent Redirect",

      # Client errors
      400 => "Bad Request",
      401 => "Unauthorized",
      403 => "Forbidden",
      404 => "Not Found",
      405 => "Method Not Allowed",
      406 => "Not Acceptable",
      407 => "Proxy Authentication Required",
      409 => "Conflict",
      410 => "Gone",
      411 => "Length Required",
      413 => "Payload Too Large",
      414 => "URI Too Long",
      415 => "Unsupported Media Type",
      421 => "Misdirected Request",
      422 => "Unprocessable Content",
      423 => "Locked",
      424 => "Failed Dependency",
      428 => "Precondition Required",
      429 => "Too Many Requests",
      431 => "Request Header Fields Too Large",

      # Server errors
      500 => "Internal Server Error",
      501 => "Not Implemented",
      502 => "Bad Gateway",
      503 => "Service Unavailable",
      504 => "Gateway Timeout"
    }

    #
    # Converts an HTTP status code to a human-readable description
    #
    # Takes a numeric status code and returns a formatted string containing both
    # the code and its description. Uses predefined descriptions for common codes,
    # with fallbacks to category-based descriptions for uncommon codes.
    #
    # @param code [Integer, String] The HTTP status code to convert
    #
    # @return [String] A formatted description string (e.g., "200 OK", "404 Not Found")
    #
    # @example Common status codes
    #   HTTP.status_code_to_description(200) # => "200 OK"
    #   HTTP.status_code_to_description(404) # => "404 Not Found"
    #
    # @example Fallback descriptions for uncommon codes
    #   HTTP.status_code_to_description(299) # => "299 Success"
    #   HTTP.status_code_to_description(499) # => "499 Client Error"
    #
    def self.status_code_to_description(code)
      code = code.to_i
      description = STATUS_DESCRIPTIONS[code]
      return "#{code} #{description}" if description

      # Fallbacks by range
      if code >= 100 && code < 200
        "#{code} Informational"
      elsif code >= 200 && code < 300
        "#{code} Success"
      elsif code >= 300 && code < 400
        "#{code} Redirection"
      elsif code >= 400 && code < 500
        "#{code} Client Error"
      elsif code >= 500 && code < 600
        "#{code} Server Error"
      else
        code.to_s
      end
    end
  end
end

require_relative "http/backend"
require_relative "http/client"
require_relative "http/verb"
require_relative "http/request"
