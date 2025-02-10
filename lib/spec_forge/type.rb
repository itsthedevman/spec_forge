# frozen_string_literal: true

module SpecForge
  module Type
    #
    # Checks if the object is a Hash, or a ResolvableHash (delegator)
    #
    # @param object [Object] The object to check
    #
    # @return [Boolean]
    #
    def self.hash?(object)
      object.is_a?(Hash) || object.is_a?(Attribute::ResolvableHash)
    end

    #
    # Checks if the object is an Array, or a ResolvableArray (delegator)
    #
    # @param object [Object] The object to check
    #
    # @return [Boolean]
    #
    def self.array?(object)
      object.is_a?(Array) || object.is_a?(Attribute::ResolvableArray)
    end
  end
end

#
# Represents Hash/ResolvableHash in a form that can be used in a case statement
#
class HashLike
  def self.===(object)
    SpecForge::Type.hash?(object)
  end
end

#
# Represents Array/ResolvableArray in a form that can be used in a case statement
#
class ArrayLike
  def self.===(object)
    SpecForge::Type.array?(object)
  end
end
