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
      #     headers: {response_header: "kind_of.string"},
      #     json: {name: {"matcher.eq" => "John"}}
      #   )
      #
      class Constraint < Data.define(:status, :headers, :json) # :xml, :html
        #
        # Creates a new constraint
        #
        # @param status [Integer, String] The expected HTTP status code, or reference to one
        # @param headers [Hash] The expected headers with matchers
        # @param json [Hash, Array] The expected JSON with matchers
        #
        # @return [Constraint] A new constraint instance
        #
        def initialize(status:, headers: {}, json: {})
          super(
            status: Attribute.from(status),
            headers: Attribute.from(headers),
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

        #
        # Generates a human-readable description of what this constraint expects in the response
        #
        # Creates a description string for RSpec examples that clearly explains the expected
        # status code and JSON structure. This makes test output more informative and helps
        # developers understand what's being tested at a glance.
        #
        # @return [String] A human-readable description of the constraint expectations
        #
        # @example Status code with JSON object
        #   constraint.description
        #   # => "is expected to respond with \"200 OK\" and a JSON object that contains keys: \"id\", \"name\""
        #
        # @example Status code with JSON array
        #   constraint.description
        #   # => "is expected to respond with \"201 Created\" and a JSON array that contains 3 items"
        #
        def description
          description = "is expected to respond with"

          description += if status.is_a?(Attribute::Literal)
            " #{HTTP.status_code_to_description(status.input).in_quotes}"
          else
            " the expected status code"
          end

          size = json.size

          if Type.array?(json)
            description +=
              " and a JSON array that contains #{size} #{"item".pluralize(size)}"
          elsif Type.hash?(json) && size > 0
            keys = json.keys.join_map(", ", &:in_quotes)

            description +=
              " and a JSON object that contains #{"key".pluralize(size)}: #{keys}"
          end

          description
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
