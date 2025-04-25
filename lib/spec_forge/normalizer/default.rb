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

        default_type_value = lambda do |type_class|
          case type_class
          when Integer
            0
          when Proc
            -> {}
          else
            type_class.new
          end
        end

        structure.each_with_object({}) do |(key, value), hash|
          type = value[:type]

          hash[key] =
            if value.key?(:default)
              default = value[:default]
              next if default.nil?

              default.dup
            elsif type.instance_of?(Array)
              default_type_value.call(type.first)
            else
              default_type_value.call(type)
            end
        end
      end
    end
  end
end
