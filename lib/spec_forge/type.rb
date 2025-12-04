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
