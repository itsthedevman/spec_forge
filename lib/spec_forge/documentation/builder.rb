# frozen_string_literal: true

module SpecForge
  module Documentation
    #
    # Transforms extracted test data into a structured document
    #
    # This class processes raw endpoint data from tests into a hierarchical document
    # structure suitable for rendering as API documentation.
    #
    # @example Creating a document from test data
    #   document = Builder.document_from_endpoints(endpoints)
    #
    class Builder
      # Source: https://gist.github.com/johnelliott/cf77003f72f889abbc3f32785fa3df8d
      UUID_REGEX = /^[0-9A-F]{8}-[0-9A-F]{4}-4[0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12}$/i
      INTEGER_REGEX = /^-?\d+$/
      FLOAT_REGEX = /^-?\d+\.\d+$/

      #
      # Creates a document from endpoint data
      #
      # @param endpoints [Array<Hash>] Array of endpoint data extracted from tests
      #
      # @return [Document] A structured documentation document
      #
      def self.document_from_endpoints(endpoints = [])
        new(endpoints).export_as_document
      end

      attr_reader :endpoints

      #
      # Initializes a new builder with endpoint data
      #
      # @param endpoints [Array<Hash>] Array of endpoint data extracted from tests
      #
      # @return [Builder] A new builder instance
      #
      def initialize(endpoints)
        @endpoints = prepare_endpoints(endpoints)
      end

      #
      # Prepares endpoint data for document creation
      #
      # Groups endpoints by path and HTTP method, sanitizes error responses,
      # merges similar operations, and flattens the result.
      #
      # @param endpoints [Array<Hash>] Raw endpoint data from tests
      #
      # @return [Hash] Processed endpoints organized by path and method
      #
      def prepare_endpoints(endpoints)
        # Step one, group the endpoints by their paths and verb
        # { path: {get: [], post: []}, path_2: {get: []}, ... }
        grouped = group_endpoints(endpoints)

        grouped.each_value do |endpoint|
          # Operations are those arrays
          endpoint.transform_values! do |operations|
            # Step two, clear data from any error (4xx, 5xx) operations
            operations = sanitize_error_operations(operations)

            # Step three, merge all of the operations into one single hash
            operations = merge_operations(operations)

            # Step four, flatten the operations into one
            flatten_operations(operations)
          end
        end
      end

      #
      # Exports the processed endpoints as a document
      #
      # @return [Document] A document containing the processed endpoints
      #
      def export_as_document
        Document.new(endpoints:)
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

      #
      # Groups endpoints by path and HTTP method
      #
      # @param endpoints [Array<Hash>] Array of endpoint data
      #
      # @return [Hash] Endpoints grouped by path and method
      #
      # @private
      #
      def group_endpoints(endpoints)
        grouped = Hash.new_nested_hash(depth: 1)

        # Convert the endpoints from a flat array of objects into a hash
        endpoints.each do |input|
          # "/users" => {}
          endpoint_hash = grouped[input[:url]]

          # "GET" => []
          (endpoint_hash[input[:http_verb]] ||= []) << input
        end

        grouped
      end

      #
      # Sanitizes operations that represent error responses
      #
      # Removes request details from operations with 4xx/5xx responses
      # to prevent invalid data from appearing in documentation.
      #
      # @param operations [Array<Hash>] Array of operations
      #
      # @return [Array<Hash>] Sanitized operations
      #
      # @private
      #
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

      #
      # Merges similar operations into a single operation
      #
      # @param operations [Array<Hash>] Array of operations
      #
      # @return [Array<Hash>] Merged operations
      #
      # @private
      #
      def merge_operations(operations)
        operations.group_by { |o| o[:response_status] }
          .transform_values { |o| flat_merge(o) }
          .values
      end

      #
      # Flattens multiple operations into a single operation structure
      #
      # @param operations [Array<Hash>] Array of operations
      #
      # @return [Hash] Flattened operation
      #
      # @private
      #
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

      #
      # Normalizes request parameters from operations
      #
      # Extracts and categorizes parameters as path or query parameters
      # and determines their data types.
      #
      # @param operations [Array<Hash>] Array of operations
      #
      # @return [Hash] Normalized parameters
      #
      # @private
      #
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

      #
      # Normalizes request bodies from operations
      #
      # Extracts request bodies from successful operations and
      # determines their data types.
      #
      # @param operations [Array<Hash>] Array of operations
      #
      # @return [Array<Hash>] Normalized request bodies
      #
      # @private
      #
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

      #
      # Normalizes responses from operations
      #
      # Extracts response details including status, headers, and body
      # and determines their data types.
      #
      # @param operations [Array<Hash>] Array of operations
      #
      # @return [Array<Hash>] Normalized responses
      #
      # @private
      #
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

      #
      # Normalizes response headers
      #
      # @param headers [Hash] Response headers
      #
      # @return [Hash] Normalized headers with types
      #
      # @private
      #
      def normalize_headers(headers)
        headers.transform_values do |value|
          {type: determine_type(value)}
        end
      end

      #
      # Normalizes response body structure
      #
      # @param body [Hash, Array, String] Response body
      #
      # @return [Hash] Normalized body structure with type information
      #
      # @private
      #
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
