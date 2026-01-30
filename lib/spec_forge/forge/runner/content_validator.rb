# frozen_string_literal: true

module SpecForge
  class Forge
    class Runner
      #
      # Validates JSON content against expected matchers
      #
      # Recursively walks through the response body and expected values,
      # running RSpec matchers at each leaf node and collecting failures.
      #
      class ContentValidator
        #
        # Creates a new content validator
        #
        # @param data [Hash, Array] The response data to validate
        # @param expected [Hash, Array] The expected content matchers
        #
        # @return [ContentValidator] A new validator instance
        #
        def initialize(data, expected)
          @data = data
          @expected = expected
          @failures = []
        end

        #
        # Validates the data against expected content matchers
        #
        # @return [void]
        #
        # @raise [Error::ContentValidationFailure] If validation fails
        #
        def validate!
          check_content(@data, @expected, path: "")

          raise Error::ContentValidationFailure.new(@failures) if @failures.any?
        end

        private

        def failure!(path, message)
          @failures << {path:, message:}
        end

        def check_content(data, expected, path:)
          case expected
          when Hash
            check_hash(data, expected, path:)
          when Array
            check_array(data, expected, path:)
          else
            run_matcher(data, expected, path:)
          end
        end

        def check_hash(data, expected, path:)
          expected.each do |key, expected_value|
            new_path = path.empty? ? ".#{key}" : "#{path}.#{key}"

            actual_key = [key.to_sym, key.to_s].detect { |k| data.respond_to?(:key?) && data.key?(k) }
            actual_value = data[actual_key]

            if actual_value.nil? && actual_key.nil?
              failure!(new_path, "key not found")
              next
            end

            check_content(actual_value, expected_value, path: new_path)
          end
        end

        def check_array(data, expected, path:)
          if !data.is_a?(Array)
            failure!(path, "expected array, got #{data.class}")
            return
          end

          expected.each_with_index do |expected_item, index|
            check_content(data[index], expected_item, path: "#{path}[#{index}]")
          end
        end

        def run_matcher(data, matcher, path:)
          return if matcher.matches?(data)

          failure!(path, matcher.failure_message.lstrip)
        end
      end
    end
  end
end
