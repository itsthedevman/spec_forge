# frozen_string_literal: true

module SpecForge
  class Forge
    class Runner
      class HeaderValidator
        def initialize(headers, expected)
          @headers = headers
          @expected = expected
          @failures = []
        end

        def validate!
          @expected.each do |key, matcher|
            actual_key = find_header_key(key)

            if actual_key.nil?
              failure!(key, "header not found")
              next
            end

            actual_value = @headers[actual_key]
            next if matcher.matches?(actual_value)

            failure!(key, matcher.failure_message.lstrip)
          end

          raise Error::HeaderValidationFailure.new(@failures) if @failures.any?
        end

        private

        def find_header_key(key)
          return key if @headers.key?(key)

          @headers.keys.find { |k| k.to_s.downcase == key.to_s.downcase }
        end

        def failure!(header, message)
          @failures << {header:, message:}
        end
      end
    end
  end
end
