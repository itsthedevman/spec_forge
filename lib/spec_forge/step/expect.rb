# frozen_string_literal: true

module SpecForge
  class Step
    #
    # Represents an expectation block within a step
    #
    # Holds the expected status, headers, and body (raw or JSON) that
    # will be validated against the HTTP response. Provides methods
    # to convert expectations into RSpec matchers.
    #
    class Expect < Data.define(:status, :headers, :raw, :json)
      def initialize(status: nil, headers: nil, raw: nil, json: nil)
        super(
          status: status ? Attribute.from(status) : nil,
          headers: extract_headers(headers),
          raw: raw ? Attribute.from(raw) : nil,
          json: extract_json(json)
        )
      end

      #
      # Returns the total number of assertions in this expectation
      #
      # Counts all non-blank assertions (status, headers, raw, JSON size/schema/content).
      #
      # @return [Integer] Number of assertions
      #
      def size
        [
          status,
          headers,
          raw,
          json[:size],
          json[:schema],
          json[:content]
        ].compact_blank.size
      end

      #
      # Returns the status code as an RSpec matcher
      #
      # @return [RSpec::Matchers::BuiltIn::BaseMatcher, nil] Status matcher or nil
      #
      def status_matcher
        return if status.blank?

        status.resolve_as_matcher
      end

      #
      # Returns headers as a hash of matchers
      #
      # @return [Hash, nil] Header matchers keyed by header name
      #
      def headers_matcher
        return if headers.blank?

        headers.transform_values(&Attribute.resolve_as_matcher_proc)
      end

      #
      # Returns the JSON size matcher
      #
      # @return [RSpec::Matchers::BuiltIn::BaseMatcher, nil] Size matcher or nil
      #
      def json_size_matcher
        json[:size]&.resolve_as_matcher
      end

      #
      # Returns the JSON schema structure for validation
      #
      # @return [Hash, nil] The schema definition or nil
      #
      def json_schema
        json[:schema]
      end

      #
      # Returns the JSON content matcher
      #
      # @return [RSpec::Matchers::BuiltIn::BaseMatcher, nil] Content matcher or nil
      #
      def json_content_matcher
        json[:content]&.resolve_as_matcher
      end

      private

      def extract_headers(headers)
        return if headers.blank?

        headers.stringify_keys.transform_values { |v| Attribute.from(v) }
      end

      def extract_json(json)
        return {} if json.blank?

        output = {}

        output[:content] = Attribute.from(json[:content]) if json[:content]
        output[:size] = Attribute.from(json[:size]) if json[:size]
        output[:schema] = json[:schema] || json[:shape]

        output
      end
    end
  end
end
