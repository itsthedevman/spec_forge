# frozen_string_literal: true

module SpecForge
  class Spec
    class Expectation
      #
      # Represents the "expect" hash
      #
      class Constraint < Data.define(:status, :json) # :xml, :html
        #
        # Creates a new Constraint
        #
        # @param status [Integer] The expected HTTP status code
        # @param json [Hash, Array] The expected JSON with matchers
        #
        def initialize(status:, json:)
          super(
            status: Attribute.from(status),
            json: convert_to_matchers(json)
          )
        end

        def to_h
          super.transform_values(&:resolve)
        end

        private

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
