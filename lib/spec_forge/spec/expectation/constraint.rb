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
        # @param json [Hash] The expected JSON with matchers
        #
        def initialize(status:, json:)
          super(status:, json: normalize_hash(json))
        end

        def to_h
          super.transform_values(&:resolve)
        end

        private

        def normalize_hash(hash)
          hash =
            hash.transform_values do |attribute|
              case attribute
              when Attribute::Regex
                Attribute.from("matcher.match" => attribute.resolve)
              when Attribute::Literal
                Attribute.from("matcher.eq" => attribute.resolve)
              else
                attribute
              end
            end

          Attribute.from(hash)
        end
      end
    end
  end
end
