# frozen_string_literal: true

module SpecForge
  class Normalizer
    module Default
      private

      def default(structure_name: nil, structure: nil)
        structure ||= @structures[structure_name]

        if !structure.is_a?(Hash)
          raise ArgumentError, "Invalid structure, provide either 'structure_name' or 'structure'"
        end

        structure.each_with_object({}) do |(key, value), hash|
          type = value[:type]

          hash[key] =
            if value.key?(:default)
              default = value[:default]
              next if default.nil?

              default.dup
            elsif type.instance_of?(Array)
              default_value_for_type(type.first)
            else
              default_value_for_type(type)
            end
        end
      end

      def default_value_for_type(type_class)
        case type_class
        when Integer
          0
        when Proc
          -> {}
        else
          type_class.new
        end
      end
    end
  end
end
