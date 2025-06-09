# frozen_string_literal: true

module SpecForge
  module Documentation
    module Generators
      module OpenAPI
        #
        # Formats OpenAPI validation errors into human-readable messages
        #
        # Takes validation errors from OpenAPI parsers and transforms them into
        # structured, easy-to-understand error messages with context information
        # and suggestions for resolution.
        #
        # @example Formatting validation errors
        #   errors = openapi_parser.errors
        #   formatted = ErrorFormatter.format(errors)
        #   puts formatted
        #
        class ErrorFormatter
          #
          # Regular expression for matching path-related validation errors
          #
          # Captures path, HTTP method, and response code from OpenAPI error contexts
          # to provide meaningful location information in error messages.
          #
          # @api private
          #
          PATHS_REGEX = %r{#/paths/(.+?)/(get|post|put|patch|delete|head|options)/responses/(.+)}i

          #
          # Regular expression for matching schema-related validation errors
          #
          # Captures schema name and field path from OpenAPI error contexts
          # to identify specific schema validation failures.
          #
          # @api private
          #
          SCHEMA_REGEX = %r{#/components/schemas/(.+?)/(.+)}i

          #
          # Formats an array of validation errors into a readable string
          #
          # @param errors [Array] Array of validation error objects
          #
          # @return [String, nil] Formatted error message or nil if no errors
          #
          def self.format(errors)
            new(errors).format
          end

          #
          # Creates a new error formatter
          #
          # @param errors [Array] Array of validation error objects to format
          #
          # @return [ErrorFormatter] A new formatter instance
          #
          def initialize(errors)
            @errors = errors
          end

          #
          # Formats the errors into a structured, readable message
          #
          # Groups errors by type (unexpected vs validation), formats each error
          # with context and location information, and returns a comprehensive
          # error report with resolution guidance.
          #
          # @return [String, nil] Formatted error message or nil if no errors
          #
          def format
            return if @errors.blank?

            unexpected_errors, errors = @errors.partition { |e| e.message.include?("Unexpected") }

            unexpected_errors = format_errors(unexpected_errors)
            errors = format_errors(errors, start_index: unexpected_errors.size)

            if unexpected_errors.size > 0
              unexpected_message = <<~STRING

                Field errors (resolve these first):

                #{unexpected_errors.join("\n\n")}

                -------

                Other validation errors:
              STRING
            end

            <<~STRING
              ========================================
              🚨 Validation Errors
              ========================================
              #{unexpected_message}
              #{errors.join("\n\n")}

              Total errors: #{errors.size}
            STRING
          end

          private

          def format_errors(errors, start_index: 0)
            errors.map.with_index do |error, index|
              format_single_error(error, start_index + index + 1)
            end
          end

          def format_single_error(error, number)
            context_path = simplify_context_path(error.context.to_s)
            error_message =
              <<~STRING
                Error ##{number}:
                  Message: #{error.message}
                  Location: #{context_path}
              STRING

            error_message += "  Type: #{error.for_type}" if error.for_type
            error_message
          end

          def simplify_context_path(context_path)
            # Clean up the basic encoding mess first
            path = context_path.gsub(/.*source_location: /, "")
              .gsub("%7B", "{")
              .gsub("%7D", "}")
              .gsub("~1", "/")
              .gsub("~0", "~")
              .gsub("%24", "$")

            # Now try to make it human-readable
            if (match = path.match(PATHS_REGEX))
              full_path, method, rest = match.captures

              "#{method.upcase} #{full_path} → responses/#{rest}"
            elsif (match = path.match(SCHEMA_REGEX))
              schema, rest = match.captures
              "Schemas → #{schema} → #{rest}"
            else
              path
            end
          end
        end
      end
    end
  end
end
