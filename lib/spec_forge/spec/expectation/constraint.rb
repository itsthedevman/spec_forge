# frozen_string_literal: true

module SpecForge
  class Spec
    class Expectation
      #
      # Represents the expected response constraints for an expectation
      #
      # A Constraint defines what the API response should look like,
      # including status code and body content with support for matchers.
      #
      # @example In code
      #   constraint = Constraint.new(
      #     status: 200,
      #     json: {name: "matcher.eq" => "John"}
      #   )
      #
      class Constraint < Data.define(:status, :json) # :xml, :html
        #
        # Creates a new constraint
        #
        # @param status [Integer, String] The expected HTTP status code, or reference to one
        # @param json [Hash, Array] The expected JSON with matchers
        #
        # @return [Constraint] A new constraint instance
        #
        def initialize(status:, json: {})
          super(
            status: Attribute.from(status),
            json: Attribute.from(json)
          )
        end

        #
        # Converts the constraint to a hash with resolved values
        #
        # @return [Hash] Hash representation with resolved values
        #
        def to_h
          super.transform_values(&:resolve)
        end

        #
        # Converts constraints to RSpec matchers for validation
        #
        # Transforms the defined constraints (status and JSON expectations) into
        # appropriate RSpec matchers that can be used in test expectations.
        # This method resolves all values and applies the appropriate matcher
        # conversions to create a complete expectation structure.
        #
        # @return [Hash] A hash containing resolved matchers
        #
        # @example
        #   constraint = Constraint.new(status: 200, json: {name: "John"})
        #   matchers = constraint.as_matchers
        #   # => {status: eq(200), json: include("name" => eq("John"))}
        #
        def as_matchers
          # Resolve then convert to ensure the values being converted to matchers are the
          # final values
          {
            status: convert_to_matchers(status.resolved).resolved,
            json: convert_to_matchers(json.resolved).resolved
          }
        end

        private

        #
        # Recursively converts the value to appropriate RSpec matchers.
        # At the root level for a Hash, only the values are converted to matchers.
        # This allows for testing specific keys in the response body while
        # nested hashes get wrapped in "include" matchers for more flexible validation.
        #
        # All other values are converted according to rules in #convert_value_to_matcher
        #
        # @param value [Object] The value to convert
        #
        # @return [Object] The value with nested structures converted to matchers
        #
        # @private
        #
        def convert_to_matchers(value)
          case value
          when HashLike
            value = value.transform_values { |v| convert_value_to_matcher(v) }.stringify_keys
            Attribute.from(value)
          else
            convert_value_to_matcher(value)
          end
        end

        #
        # Converts nested values to appropriate RSpec matchers
        # Used for all values below the root level
        #
        # @param value [Object] The value to convert to a matcher
        #
        # @return [Object] The appropriate matcher for the value:
        #   - Hashes become include matchers
        #   - Arrays become contain_exactly matchers
        #   - Regex values become match matchers
        #   - Other values become eq matchers
        #   - Existing matchers are passed through
        #
        # @private
        #
        def convert_value_to_matcher(value)
          case value
          when HashLike
            value = value.transform_values { |v| convert_value_to_matcher(v) }.stringify_keys
            Attribute.from("matcher.include" => value)
          when ArrayLike
            value = value.map { |i| convert_value_to_matcher(i) }
            Attribute.from("matcher.contain_exactly" => value)
          when Regexp
            Attribute.from("matcher.match" => value)
          when RSpec::Matchers::BuiltIn::BaseMatcher
            value
          else
            Attribute.from("matcher.eq" => value)
          end
        end
      end
    end
  end
end
