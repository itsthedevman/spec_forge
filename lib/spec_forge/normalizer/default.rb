# frozen_string_literal: true

module SpecForge
  class Normalizer
    module Default
      private

      def default_from_structure(structure, include_optional: false)
        structure.each_with_object({}) do |(attribute_name, attribute), hash|
          type = attribute[:type]
          has_default = attribute.key?(:default)
          required = attribute[:required]

          next if !(include_optional || required || has_default)

          hash[attribute_name] =
            if has_default
              default = attribute[:default]
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
        if type_class == Integer
          0
        elsif type_class == Proc
          -> {}
        elsif type_class == TrueClass
          true
        elsif type_class == FalseClass
          false
        else
          type_class.new
        end
      end
    end
  end
end
