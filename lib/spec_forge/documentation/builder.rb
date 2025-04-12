# frozen_string_literal: true

module SpecForge
  module Documentation
    class Builder
      # Source: https://gist.github.com/johnelliott/cf77003f72f889abbc3f32785fa3df8d
      UUID_REGEX = /^[0-9A-F]{8}-[0-9A-F]{4}-4[0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12}$/i
      INTEGER_REGEX = /^-?\d+$/
      FLOAT_REGEX = /^-?\d+\.\d+$/

      def self.build(endpoints: [], structures: [])
        new(endpoints:, structures:)
          .prepare_endpoints
          .export_as_document
      end

      attr_reader :info, :endpoints, :structures

      def initialize(endpoints:, structures:)
        @info = Documentation.config[:info]
        @endpoints = endpoints
        @structures = structures
      end

      def prepare_endpoints
        # Step one, group the endpoints
        endpoints = grouped_endpoints

        endpoints.each_value do |endpoint|
          endpoint.transform_values! do |operations|
            # Step two, clear data from any error (4xx, 5xx) operations
            operations = sanitize_error_operations(operations)

            # Step three, merge all of the operations into one single hash
            operations = merge_operations(operations)

            # Step four, flatten the operations into one
            flatten_operations(operations)
          end
        end

        @endpoints = endpoints

        self
      end

      def export_as_document
        Document.new(info:, endpoints:, structures:)
      end

      private

      def flat_merge(array)
        array.each_with_object({}) do |hash, output|
          output.deep_merge!(hash)
        end
      end

      def determine_type(value)
        case value
        when true, false
          "boolean"
        when Float
          # According to the docs: A Float object represents a sometimes-inexact real number
          # using the native architecture’s double-precision floating point representation.
          # So a double it is!
          "double"
        when Integer
          "integer"
        when Array
          "array"
        when NilClass
          "null"
        when DateTime, Time
          "datetime"
        when Date
          "date"
        when String, Symbol
          if value.match?(UUID_REGEX)
            "uuid"
          elsif value.match?(INTEGER_REGEX)
            "integer"
          elsif value.match?(FLOAT_REGEX)
            "double"
          elsif value == "true" || value == "false"
            "boolean"
          else
            "string"
          end
        when URI
          "uri"
        when Numeric
          "number"
        else
          "object"
        end
      end

      def grouped_endpoints
        endpoints = Hash.new { |h, k| h[k] = {} }

        # Convert the endpoints from a flat array of objects into a hash
        @endpoints.each do |input|
          # "/users" => {}
          endpoint_hash = endpoints[input[:url]]

          # "GET" => []
          (endpoint_hash[input[:http_verb]] ||= []) << input
        end

        endpoints
      end

      def sanitize_error_operations(operations)
        operations.each do |operation|
          next unless operation[:response_status] >= 400

          # This keeps tests that handle errors from including their invalid attributes
          # and such in the output.
          operation[:request_query] = {}
          operation[:request_headers] = {}
          operation[:request_body] = {}
        end
      end

      def merge_operations(operations)
        operations.group_by { |o| o[:response_status] }
          .transform_values { |o| flat_merge(o) }
          .values
      end

      def flatten_operations(operations)
        id = operations.key_map(:spec_name).reject(&:blank?).first

        description = operations.key_map(:expectation_name)
          .reject(&:blank?)
          .first
          &.split(" - ")
          &.second || ""

        parameters = normalize_parameters(operations)
        requests = normalize_requests(operations)
        responses = normalize_responses(operations)

        {
          id:,
          description:,
          parameters:,
          requests:,
          responses:
        }
      end

      def normalize_parameters(operations)
        parameters = {}

        operations.each do |operation|
          # Store the URL so it can be determined if the param is in the path or not
          url = operation[:url]
          params = operation[:request_query].transform_values { |value| {value:, url:} }

          parameters.merge!(params)
        end

        parameters.transform_values!.with_key do |key, data|
          key_in_path = data[:url].include?("{#{key}}")

          {
            location: key_in_path ? "path" : "query",
            type: determine_type(data[:value])
          }
        end
      end

      def normalize_requests(operations)
        successful_operations = operations.select { |o| o[:response_status] < 400 }
        return [] if successful_operations.blank?

        successful_operations.filter_map.with_index do |operation, index|
          content = operation[:request_body]
          next if content.blank?

          name = operation[:expectation_name].split(" - ").second

          {
            name: name || "Example #{index}",
            content_type: operation[:content_type],
            type: determine_type(content),
            content:
          }
        end
      end

      def normalize_responses(operations)
        operations.map do |operation|
          {
            content_type: operation[:content_type],
            status: operation[:response_status],
            headers: normalize_headers(operation[:response_headers]),
            body: normalize_response_body(operation[:response_body])
          }
        end
      end

      def normalize_headers(headers)
        headers.transform_values do |value|
          {type: determine_type(value)}
        end
      end

      def normalize_response_body(body)
        proc = lambda do |value|
          {type: determine_type(value)}
        end

        case body
        when Hash
          {
            type: "object",
            content: body.deep_transform_values(&proc)
          }
        when Array
          {
            type: "array",
            content: body.map(&proc)
          }
        when String
          {
            type: "string",
            content: body
          }
        else
          raise "Unexpected body: #{body.inspect}"
        end
      end
    end
  end
end
