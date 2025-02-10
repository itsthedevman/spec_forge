# frozen_string_literal: true

module SpecForge
  class Attribute
    class Faker < Parameterized
      KEYWORD_REGEX = /^faker\./i

      attr_reader :faker_class, :faker_method

      #
      # Represents any attribute that is a faker call
      #
      #   faker.<faker_class>.<faker_method>
      #
      def initialize(...)
        super

        # As of right now, Faker only goes 2 sub classes deep. I've added +2 padding just in case
        # faker.class.method
        # faker.class.subclass.method
        sections = input.split(".")[0..5]

        class_name = sections[0..-2].join("::").underscore.classify
        method_name = sections.last

        # Load the class
        @faker_class = begin
          "::#{class_name}".constantize
        rescue NameError
          raise InvalidFakerClassError, class_name
        end

        # Load the method
        @faker_method = begin
          faker_class.method(method_name)
        rescue NameError
          raise InvalidFakerMethodError.new(method_name, faker_class)
        end

        prepare_arguments!
      end

      def value
        if uses_positional_arguments?(faker_method)
          faker_method.call(*arguments[:positional].resolve)
        elsif uses_keyword_arguments?(faker_method)
          faker_method.call(**arguments[:keyword].resolve)
        else
          faker_method.call
        end
      end
    end
  end
end
