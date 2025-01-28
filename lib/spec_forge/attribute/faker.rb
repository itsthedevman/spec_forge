# frozen_string_literal: true

module SpecForge
  class Attribute
    class Faker < Attribute
      attr_reader :faker_class, :faker_method, :arguments

      def initialize(input, positional = [], keyword = {})
        super(input)

        @arguments = {positional:, keyword:}

        # faker.class.method
        sections = @input.split(".")[1..2]

        class_name = sections.first.underscore.classify
        method_name = sections.second

        # Load the class
        @faker_class = begin
          "::Faker::#{class_name}".constantize
        rescue NameError
          raise InvalidFakerClass, class_name
        end

        # Load the method
        @faker_method = begin
          @faker_class.method(method_name)
        rescue NameError
          raise InvalidFakerMethod.new(method_name, class_name)
        end
      end

      def value
        if uses_positional_arguments?
          @faker_method.call(*@arguments[:positional])
        elsif uses_keyword_arguments?
          @faker_method.call(**@arguments[:keyword])
        else
          @faker_method.call
        end
      end

      private

      def uses_positional_arguments?
        @faker_method.parameters.any? { |a| [:req, :opt].include?(a.first) }
      end

      def uses_keyword_arguments?
        @faker_method.parameters.any? { |a| [:keyreq, :key].include?(a.first) }
      end
    end
  end
end
