# frozen_string_literal: true

module SpecForge
  class Attribute
    class Faker < Attribute
      attr_reader :faker_class, :faker_method, :arguments

      def initialize(input, positional = [], keyword = {})
        super(input)

        @arguments = {positional:, keyword:}

        # faker.class.method
        class_name, method_name = @input.split(".")[1..]

        @faker_class = "::Faker::#{class_name.titleize}".constantize
        @faker_method = @faker_class.method(method_name)
      end

      def value
        if uses_positional_arguments?
          @faker_method.call(@arguments[:positional])
        elsif uses_keyword_arguments?
          @faker_method.call(@arguments[:keyword])
        else
          @faker_method.call
        end
      end

      private

      def uses_positional_arguments?
        @faker_method.parameters.any? { |a| [:req, :opt].include?(a.first) }
      end

      def uses_keyword_arguments?(method)
        @faker_method.parameters.any? { |a| [:keyreq, :key].include?(a.first) }
      end
    end
  end
end
