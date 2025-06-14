# frozen_string_literal: true

#
# Extensions to Ruby's Array class for SpecForge functionality
#
# Adds utility methods used throughout SpecForge for array manipulation
# and data processing.
#
class Array
  #
  # Merges an array of hashes into a single hash
  #
  # Performs a deep merge on each hash in the array, combining them
  # into a single hash with all keys and values.
  #
  # @return [Hash] A hash containing the merged contents of all hashes in the array
  #
  # @example Merging an array of hashes
  #   [{a: 1}, {b: 2}, {a: 3}].to_merged_h
  #   # => {a: 3, b: 2}
  #
  def to_merged_h
    each_with_object({}) do |hash, output|
      output.deep_merge!(hash)
    end
  end
end
