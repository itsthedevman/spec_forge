# frozen_string_literal: true

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
