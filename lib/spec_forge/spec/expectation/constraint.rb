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
            json: convert_to_matchers(json)
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

        private

        #
        # Converts a value to the appropriate matcher
        #
        # Applies different matchers based on the type:
        # - Hashes use matcher.include
        # - Arrays use matcher.contain_exactly
        # - Regexes use matcher.match
        # - Literals use matcher.eq
        #
        # @param value [Object] The value to convert
        #
        # @return [Attribute] The value wrapped in appropriate matcher
        #
        # @private
        #
        def convert_to_matchers(value)
          # This makes it easier to check if json was provided
          return Attribute.from(nil) if value.blank?

          value = Attribute.from(value)

          case value
          when HashLike
            value = value.transform_values { |i| convert_to_matchers(i) }
            Attribute.from("matcher.include" => value)
          when ArrayLike
            value = value.map { |i| convert_to_matchers(i) }
            Attribute.from("matcher.contain_exactly" => value)
          when Attribute::Regex
            Attribute.from("matcher.match" => value)
          when Attribute::Literal
            Attribute.from("matcher.eq" => value)
          else
            value
          end
        end
      end
    end
  end
end
