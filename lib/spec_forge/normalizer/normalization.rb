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

        structure = @structures[structure_name]
        if structure.nil?
          structures = @structures.keys.to_or_sentence

          raise ArgumentError,
            "Invalid structure name. Expected #{structures}, got #{structure_name&.in_quotes}"
        end

        new(label, input, structure:).normalize
      end

      #
      # Raises any errors collected by the block
      #
      # @yield Block that returns [output, errors]
      # @yieldreturn [Array<Object, Set>] The result and any errors
      #
      # @return [Object] The normalized output if successful
      #
      # @raise [Error::InvalidStructureError] If any errors were encountered
      #
      # @api private
      #
      def raise_errors!(&block)
        errors = Set.new

        begin
          output, new_errors = yield
          errors.merge(new_errors) if new_errors.size > 0
        rescue => e
          errors << e
        end

        raise Error::InvalidStructureError.new(errors) if errors.size > 0

        output
      end
    end
  end
end
