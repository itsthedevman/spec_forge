# frozen_string_literal: true

module SpecForge
  class Spec
    class Expectation
      class Constraint < Data.define(:status, :json) # :xml, :html
        def initialize(**options)
          status = options[:status]
          json = Attribute::ResolvableHash.new(normalize_hash(options[:json]))

          super(status:, json:)
        end

        private

        def normalize_hash(hash)
          hash.transform_values do |attribute|
            if attribute.is_a?(Attribute::Literal)
              normalize_literal(attribute.value)
            else
              attribute
            end
          end
        end

        def normalize_literal(value)
          if value.is_a?(Regexp)
            Attribute.from({"matcher.match" => value})
          else
            Attribute.from({"matcher.eq" => value})
          end
        end
      end
    end
  end
end
