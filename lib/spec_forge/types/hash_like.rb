# frozen_string_literal: true

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
