# frozen_string_literal: true

module SpecForge
  #
  # Provides helper methods for checking types
  # Useful for working with both regular objects and Attribute delegators
  #
  module Type
    #
    # Checks if the object is a Hash or a ResolvableHash delegator
    #
    # @param object [Object] The object to check
    #
    # @return [Boolean] True if the object is a hash-like structure
    #
    def self.hash?(object)
      object.is_a?(Hash) || object.is_a?(Attribute::ResolvableHash)
    end

    #
    # Checks if the object is an Array or a ResolvableArray delegator
    #
    # @param object [Object] The object to check
    #
    # @return [Boolean] True if the object is an array-like structure
    #
    def self.array?(object)
      object.is_a?(Array) || object.is_a?(Attribute::ResolvableArray)
    end
  end
end

#
# Represents Hash/ResolvableHash in a form that can be used in a case statement
# Allows for type switching on hash-like objects
#
# @example
#   case value
#   when HashLike
#     # Handle hash-like objects
#   end
#
class HashLike
  #
  # Provides custom type matching for use in case statements
  #
  # @param object [Object] The object to check against the type
  #
  # @return [Boolean] Whether the object matches the type
  #
  def self.===(object)
    SpecForge::Type.hash?(object)
  end
end

#
# Represents Array/ResolvableArray in a form that can be used in a case statement
# Allows for type switching on array-like objects
#
# @example
#   case value
#   when ArrayLike
#     # Handle array-like objects
#   end
#
class ArrayLike
  #
  # Provides custom type matching for use in case statements
  #
  # @param object [Object] The object to check against the type
  #
  # @return [Boolean] Whether the object matches the type
  #
  def self.===(object)
    SpecForge::Type.array?(object)
  end
end
