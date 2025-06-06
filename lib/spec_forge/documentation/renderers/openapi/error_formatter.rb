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
            return "✅ No validation errors found!" if @errors.blank?

            errors =
              @errors.map.with_index do |error, index|
                format_single_error(error, index + 1)
              end

            <<~STRING
              ========================================
              🚨 Validation Errors
              ========================================

              #{errors.join("\n\n")}

              Total errors: #{errors.size}
            STRING
          end

          private

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
