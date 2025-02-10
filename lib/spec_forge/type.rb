# frozen_string_literal: true

module SpecForge
  module Type
    def self.hash?(object)
      object.is_a?(Hash) || object.is_a?(Attribute::ResolvableHash)
    end

    def self.array?(object)
      object.is_a?(Array) || object.is_a?(Attribute::ResolvableArray)
    end
  end
end

class HashLike
  def self.===(object)
    SpecForge::Type.hash?(object)
  end
end

class ArrayLike
  def self.===(object)
    SpecForge::Type.array?(object)
  end
end
