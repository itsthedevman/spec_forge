# frozen_string_literal: true

module SpecForge
  class Attribute
    class ResolvableStruct < SimpleDelegator
      include Resolvable

      def value
        __getobj__
      end

      def resolved
        hash = value.to_h.transform_values(&resolved_proc)
        to_structlike(hash)
      end

      def resolve
        hash = value.to_h.transform_values(&resolve_proc)
        to_structlike(hash)
      end

      def resolve_as_matcher
        result = value.to_h.transform_values(&resolve_as_matcher_proc)
        Attribute::Literal.new(result).resolve_as_matcher
      end

      private

      def to_structlike(hash)
        case value
        when OpenStruct
          hash.to_ostruct
        when Data
          hash.to_istruct
        else
          hash.to_struct
        end
      end
    end
  end
end
