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

        private

        def normalize_hash(hash)
          hash =
            hash.transform_values do |attribute|
              if attribute.is_a?(Attribute::Literal)
                normalize_literal(attribute.value)
              else
                attribute
              end
            end

          Attribute.from(hash)
        end

        def normalize_literal(value)
          if value.is_a?(Regexp)
            Attribute.from("matcher.match" => value)
          else
            Attribute.from("matcher.eq" => value)
          end
        end
      end
    end
  end
end
