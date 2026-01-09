# frozen_string_literal: true

module SpecForge
  class Forge
    class Runner
      #
      # Validates HTTP response headers against expected matchers
      #
      # Performs case-insensitive header name matching and runs
      # RSpec matchers against header values.
      #
      class HeaderValidator
        #
        # Creates a new header validator
        #
        # @param headers [Hash] The response headers to validate
        # @param expected [Hash] The expected header matchers
        #
        # @return [HeaderValidator] A new validator instance
        #
        def initialize(headers, expected)
          @headers = headers
          @expected = expected
          @failures = []
        end

        #
        # Validates the headers against expected matchers
        #
        # @return [void]
        #
        # @raise [Error::HeaderValidationFailure] If validation fails
        #
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
