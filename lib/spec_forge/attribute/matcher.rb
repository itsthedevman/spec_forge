# frozen_string_literal: true

module SpecForge
  class Attribute
    class Matcher < Parameterized
      KEYWORD_REGEX = /^matcher\.|^be\.|^kind_of\./i

      attr_reader :matcher_method

      # RSpec::Matchers.public_instance_methods for all matchers
      def initialize(...)
        super

        sections = input.split(".")

        case sections.size
        when 1
          method = sections.first
        when 2
          namespace = sections.first
          method = sections.second
        else
          raise InvalidMatcherError.new(input)
        end

        @matcher_method =
          case namespace
          when "be"
            resolve_be_method(method)
          when "kind_of"
            resolve_kind_of_matcher(method)
          else
            resolve_matcher(method)
          end

        raise "Invalid matcher" if @matcher_method.nil?
      end

      def value
        if uses_positional_arguments?(matcher_method)
          matcher_method.call(*arguments[:positional])
        elsif uses_keyword_arguments?(matcher_method)
          matcher_method.call(**arguments[:keyword])
        else
          matcher_method.call
        end
      end

      private

      def resolve_matcher(method_name, namespace: RSpec::Matchers)
        namespace.public_instance_method(method_name)
      end

      def resolve_be_matcher(method)
        case method

        # be.>(*args)
        when "greater_than", "greater"
          resolve_matcher(">", namespace: Matchers::BuiltIn::Be)

        # be.>=(*args)
        when "greater_than_or_equal", "greater_or_equal"
          resolve_matcher(">=", namespace: Matchers::BuiltIn::Be)

        # be.<(*args)
        when "less_than", "less"
          resolve_matcher("<", namespace: Matchers::BuiltIn::Be)

        # be.<=(*args)
        when "less_than_or_equal", "less_or_equal"
          resolve_matcher("<=", namespace: Matchers::BuiltIn::Be)

        # be(nil)
        when "nil"
          arguments[:positional].insert(0, nil)
          resolve_matcher("be")

        else
          resolve_matcher("be_#{method}")
        end
      end

      def resolve_kind_of_matcher(method)
        type_class = Object.const_get(method.capitalize)
        arguments[:positional].insert(0, type_class)

        resolve_matcher(:be_kind_of)
      end
    end
  end
end
