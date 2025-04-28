# frozen_string_literal: true

module SpecForge
  class Normalizer
    module Normalization
      private

      #
      # @api private
      #
      def normalize(input, structure_name:, label: self.label)
        raise Error::InvalidTypeError.new(input, Hash, for: label) if !Type.hash?(input)

        structure = @structures[structure_name.to_s]
        if structure.nil?
          structures = @structures.keys.to_or_sentence

          raise ArgumentError,
            "Invalid structure name. Expected #{structures}, got #{structure_name&.in_quotes}"
        end

        new(label, input, structure:).normalize
      end
    end
  end
end
