# frozen_string_literal: true

module SpecForge
  class Forge
    class Runner
      class Assayer
        class ShapeValidator
          def initialize(rspec, data, structure)
            @rspec = rspec
            @data = data
            @structure = structure
            @failures = []
          end

          def validate!
            check_structure(@data, @structure, path: "")

            raise Error::ShapeValidationFailure.new(@failures) if @failures.size > 0
          end

          private

          def check_structure(data, structure, path:)
            case structure
            when Array
              check_array_structure(data, structure, path:)
            when Hash
              check_hash_structure(data, structure, path:)
            else
              check_type(data, structure, path:)
            end
          end

          def check_array_structure(data, structure, path:)
            if type_union?(structure)
              check_type_union(data, structure, path:)
            else
              check_array_elements(data, structure, path:)
            end
          end

          def type_union?(structure)
            structure.all? { |item| item.is_a?(Class) }
          end

          def check_type_union(data, types, path:)
            return if types.any? { |type| data.is_a?(type) }

            add_failure(path, types, data)
          end

          def check_array_elements(data, structure, path:)
            structure.each_with_index do |expected, index|
              check_structure(data[index], expected, path: "#{path}[#{index}]")
            end
          end

          def check_hash_structure(data, structure, path:)
            structure.each do |key, expected|
              key_path = path.empty? ? ".#{key}" : "#{path}.#{key}"
              check_hash_key(data, key, expected, path: key_path)
            end
          end

          def check_hash_key(data, key, expected, path:)
            unless data.respond_to?(:key?) && data.key?(key)
              add_failure(path, expected, nil)
              return
            end

            check_structure(data[key], expected, path:)
          end

          def check_type(data, expected_type, path:)
            return if data.is_a?(expected_type)

            add_failure(path, expected_type, data)
          end

          def add_failure(path, expected_type, actual_value)
            @failures << {
              path: path,
              expected_type: expected_type,
              actual_value: actual_value,
              actual_type: actual_value.class
            }
          end
        end
      end
    end
  end
end
