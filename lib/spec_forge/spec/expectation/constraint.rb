# frozen_string_literal: true

module SpecForge
  class Spec
    class Expectation
      class Constraint < Data.define(:status, :json) # :xml, :html
        def initialize(**options)
          status =
            case (status = options[:status]&.value)
            when String
              Attribute.from(status.to_i)
            when Integer
              Attribute.from(status)
            else
              raise InvalidTypeError.new(status, "Integer | String", for: "'status' on constraint")
            end

          json = options[:json]&.value || {}
          if !json.is_a?(Hash)
            raise InvalidTypeError.new(json, Hash, for: "'json' on constraint")
          end

          super(status:, json: Attribute::Resolvable.new(json))
        end
      end
    end
  end
end
