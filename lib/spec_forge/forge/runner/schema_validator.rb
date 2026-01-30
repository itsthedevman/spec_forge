# frozen_string_literal: true

module SpecForge
  class Forge
    class Runner
      #
      # Validates JSON structure against a schema definition
      #
      # Validates that response data matches the expected types and structure
      # defined in shape: or schema: blocks. Supports nested objects, arrays
      # with patterns, and nullable types.
      #
      class SchemaValidator
        #
        # Creates a new schema validator
        #
        # @param data [Hash, Array] The response data to validate
        # @param schema [Hash] The schema definition to validate against
        #
        # @return [SchemaValidator] A new validator instance
        #
        def initialize(data, schema)
          @data = data
          @schema = schema
          @failures = []
        end

        #
        # Validates the data against the schema definition
        #
        # @return [void]
        #
        # @raise [Error::SchemaValidationFailure] If validation fails
        #
        def validate!
          check_schema(@data, @schema, path: "")

          raise Error::SchemaValidationFailure.new(@failures) if @failures.size > 0
        end

        private

        def failure!(path, expected_type, actual_value)
          @failures << {
            path: path.empty? ? "root" : path,
            expected_type:,
            actual_value:,
            actual_type: actual_value.class
          }
        end

        def check_schema(data, schema, path:)
          check_type(data, schema[:type], path:)
          check_structure(data, schema[:structure], path:) if schema[:structure]
          check_pattern(data, schema[:pattern], path:) if schema[:pattern]
        end

        def check_type(data, expected_types, path:)
          return if expected_types.any? { |type| data.is_a?(type) }

          failure!(path, expected_types, data)
        end

        def check_structure(data, schema, path:)
          case schema
          when Hash
            check_hash_structure(data, schema, path:)
          when Array
            check_array_structure(data, schema, path:)
          end
        end

        def check_pattern(data, schema, path:)
          # Only arrays allowed
          check_type(data, [Array], path:)

          data.each_with_index do |value, index|
            check_schema(value, schema, path: "#{path}[#{index}]")
          end
        end

        def check_hash_structure(data, structure, path:)
          structure.each do |key, expected|
            check_hash_key(
              data, key, expected,
              path: path.empty? ? ".#{key}" : "#{path}.#{key}"
            )
          end
        end

        def check_hash_key(data, key, expected, path:)
          actual_key = [key.to_sym, key.to_s].detect { |k| data.respond_to?(:key?) && data.key?(k) }

          if actual_key
            check_schema(data[actual_key], expected, path:)
            return
          end

          # Key is missing - only fail if not optional
          return if expected[:optional]

          failure!(path, expected[:type], nil)
        end

        def check_array_structure(data, structure, path:)
          structure.each_with_index do |expected, index|
            check_schema(data[index], expected, path: "#{path}[#{index}]")
          end
        end
      end
    end
  end
end
