# frozen_string_literal: true

module SpecForge
  class Attribute
    class Faker < Parameterized
      include Chainable

      KEYWORD_REGEX = /^faker\./i

      attr_reader :faker_class, :faker_method

      #
      # Represents any attribute that is a faker call
      #
      #   faker.<faker_class>.<faker_method>
      #
      def initialize(...)
        super

        @faker_class, @faker_method = extract_faker_call

        prepare_arguments!
      end

      private

      def base_object
        if (positional = arguments[:positional]) && positional.present?
          faker_method.call(*positional.resolve)
        elsif (keyword = arguments[:keyword]) && keyword.present?
          faker_method.call(**keyword.resolve)
        else
          faker_method.call
        end
      end

      def extract_faker_call
        class_name = header.downcase.to_s

        # Simple case: faker.<header>.<method>
        if invocation_chain.size == 1
          return resolve_faker_class_and_method(class_name, invocation_chain.shift)
        end

        # Try each part of the chain as a potential class name
        # Example: faker.games.zelda.game.underscore
        namespace = []

        while invocation_chain.any?
          part = invocation_chain.first.downcase
          test_class_name = ([class_name] + namespace + [part]).map(&:camelize).join("::")

          begin
            "::Faker::#{test_class_name}".constantize

            namespace << invocation_chain.shift
          rescue NameError
            # This part isn't a valid class, so it must be our method
            method_name = invocation_chain.shift
            class_name = ([class_name] + namespace).map(&:camelize).join("::")

            return resolve_faker_class_and_method(class_name, method_name)
          end
        end

        # If we get here, we consumed all parts as classes but found no method
        class_name = ([class_name] + namespace).map(&:camelize).join("::")
        raise InvalidFakerMethodError.new(nil, "::#{class_name}".constantize)
      end

      def resolve_faker_class_and_method(class_name, method_name)
        # Load the class
        faker_class = begin
          "::Faker::#{class_name.camelize}".constantize
        rescue NameError
          raise InvalidFakerClassError, class_name
        end

        # Load the method
        faker_method = begin
          faker_class.method(method_name)
        rescue NameError
          raise InvalidFakerMethodError.new(method_name, faker_class)
        end

        [faker_class, faker_method]
      end
    end
  end
end
