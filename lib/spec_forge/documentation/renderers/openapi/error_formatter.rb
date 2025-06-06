# frozen_string_literal: true

module SpecForge
  module Documentation
    module Renderers
      module OpenAPI
        class ErrorFormatter
          PATHS_REGEX = %r{#/paths/(.+?)/(get|post|put|patch|delete|head|options)/responses/(.+)}i
          SCHEMA_REGEX = %r{#/components/schemas/(.+?)/(.+)}i

          def self.format(errors)
            new(errors).format
          end

          def initialize(errors)
            @errors = errors
          end

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
