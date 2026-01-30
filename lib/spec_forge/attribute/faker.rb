# frozen_string_literal: true

module SpecForge
  class Attribute
    #
    # Represents an attribute that generates fake data using the Faker gem
    #
    # This class allows SpecForge to integrate with the Faker library to generate realistic
    # test data like names, emails, addresses, etc.
    #
    # @example Basic usage in YAML
    #   name: faker.name.name
    #   email: faker.internet.email
    #
    # @example With method arguments
    #   age:
    #     faker.number.between:
    #       from: 18
    #       to: 65
    #
    # @example Handles nested faker classes
    #   character: faker.games.zelda.character
    #
    class Faker < Parameterized
      include Chainable

      #
      # Regular expression pattern that matches attribute keywords with this prefix
      # Used for identifying this attribute type during parsing
      #
      # @return [Regexp]
      #
      KEYWORD_REGEX = /^faker\./i

      # @return [Class] The Faker class
      attr_reader :faker_class

      # @return [Method] The Faker class method
      attr_reader :faker_method

      #
      # Creates a new faker attribute with the specified name and arguments
      #
      # @raise [Error::InvalidFakerClassError] If the faker class doesn't exist
      # @raise [Error::InvalidFakerMethodError] If the faker method doesn't exist
      #
      # @see Parameterized#initialize
      #
      def initialize(...)
        super

        @faker_class, @faker_method = extract_faker_call

        prepare_arguments
      end

      #
      # Returns the base object for the variable chain
      #
      # @return [Object] The result of the Faker call
      #
      def base_object
        if (positional = arguments[:positional]) && positional.present?
          faker_method.call(*positional.resolved)
        elsif (keyword = arguments[:keyword]) && keyword.present?
          faker_method.call(**keyword.resolved)
        else
          faker_method.call
        end
      end

      private

      #
      # Extracts the Faker class and method from the input string
      # Handles both simple cases like "faker.name.first_name" and complex
      # nested namespaces like "faker.games.zelda.game"
      #
      # @return [Array<Class, Method>] A two-element array containing:
      #   1. The resolved Faker class (e.g., Faker::Name)
      #   2. The method object to call on that class (e.g., #first_name)
      #
      # @raise [Error::InvalidFakerClassError] If the specified Faker class doesn't exist
      # @raise [Error::InvalidFakerMethodError] If the specified method doesn't exist on the class
      #
      # @private
      #
      def extract_faker_call
        class_name = header.downcase.to_s

        # Simple case: faker.<header>.<method>
        if invocation_chain.size == 1
          return resolve_faker_class_and_method(class_name, invocation_chain.shift)
        end

        namespace = []

        # Try each part of the chain as a potential class name
        # Example: faker.games.zelda.game.underscore
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
        raise Error::InvalidFakerMethodError.new(nil, "::#{class_name}".constantize)
      end

      #
      # @private
      #
      def resolve_faker_class_and_method(class_name, method_name)
        # Load the class
        faker_class = begin
          "::Faker::#{class_name.camelize}".constantize
        rescue NameError
          raise Error::InvalidFakerClassError, class_name
        end

        # Load the method
        faker_method = begin
          faker_class.method(method_name)
        rescue NameError
          raise Error::InvalidFakerMethodError.new(method_name, faker_class)
        end

        [faker_class, faker_method]
      end
    end
  end
end
