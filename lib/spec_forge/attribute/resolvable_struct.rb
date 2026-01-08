# frozen_string_literal: true

module SpecForge
  class Attribute
    #
    # Wraps struct-like objects (Struct, Data, OpenStruct) to make them resolvable
    #
    # Provides resolution capabilities for struct-like objects, allowing their
    # values to be resolved recursively while maintaining the original struct type.
    #
    class ResolvableStruct < SimpleDelegator
      include Resolvable

      #
      # Returns the wrapped struct object
      #
      # @return [Struct, Data, OpenStruct] The underlying struct-like object
      #
      def value
        __getobj__
      end

      #
      # Returns the struct with all values fully resolved and cached
      #
      # @return [Struct, Data, OpenStruct] A new struct-like object with resolved values
      #
      def resolved
        hash = value.to_h.transform_values(&resolved_proc)
        to_structlike(hash)
      end

      #
      # Returns the struct with all values resolved (not cached)
      #
      # @return [Struct, Data, OpenStruct] A new struct-like object with resolved values
      #
      def resolve
        hash = value.to_h.transform_values(&resolve_proc)
        to_structlike(hash)
      end

      #
      # Converts the struct's values into RSpec matchers
      #
      # @return [RSpec::Matchers::BuiltIn::BaseMatcher] An RSpec matcher for the struct
      #
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
