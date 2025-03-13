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
          {
            status: status.resolve_as_matcher,
            json: resolve_json_matcher
          }
        end

        private

        def resolve_json_matcher
          case json
          when HashLike
            json.transform_values(&:resolve_as_matcher).stringify_keys
          else
            json.resolve_as_matcher
          end
        end
      end
    end
  end
end
