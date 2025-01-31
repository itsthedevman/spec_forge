# frozen_string_literal: true

module SpecForge
  class Attribute
    class Matcher < Parameterized
      KEYWORD_REGEX = /^matcher\.|^be\.|^kind_of\./i

      attr_reader :matcher_method

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
            resolve_be_matcher(method)
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
        # Resolve any custom matchers
        resolved_matcher =
          case method

          # be.>(*args)
          when "greater_than", "greater"
            resolve_matcher(">", namespace: RSpec::Matchers::BuiltIn::Be)

          # be.>=(*args)
          when "greater_than_or_equal", "greater_or_equal"
            resolve_matcher(">=", namespace: RSpec::Matchers::BuiltIn::Be)

          # be.<(*args)
          when "less_than", "less"
            resolve_matcher("<", namespace: RSpec::Matchers::BuiltIn::Be)

          # be.<=(*args)
          when "less_than_or_equal", "less_or_equal"
            resolve_matcher("<=", namespace: RSpec::Matchers::BuiltIn::Be)

          # be(nil)
          when "nil"
            arguments[:positional].insert(0, nil)
            resolve_matcher("be")

          # be(true)
          when "true"
            arguments[:positional].insert(0, true)
            resolve_matcher("be")

          # be(false)
          when "false"
            arguments[:positional].insert(0, false)
            resolve_matcher("be")
          end

        # Return the matcher if we found one
        return resolved_matcher if resolved_matcher

        # No matcher found yet, maybe it is prefixed with "be_"?
        return resolve_matcher("be_#{method}") if defined_matcher?("be_#{method}")

        # Ok, so maybe it's one of those dynamic predicates, be_<predicate>
        # Let's set up for that
        arguments[:positional].insert(0, :"be_#{method}")

        # We are expecting a method to call that returns a Matcher
        # Since we don't have a method, we'll create our own and use it as a proxy
        self.method(:dispatch_dynamic_predicate)
      end

      def resolve_kind_of_matcher(method)
        type_class = Object.const_get(method.capitalize)
        arguments[:positional].insert(0, type_class)

        resolve_matcher(:be_kind_of)
      end

      def defined_matcher?(method)
        RSpec::Matchers.public_instance_methods.include?(method.to_sym)
      end

      # RSpec handles these via method_missing and wraps them in BePredicate
      def dispatch_dynamic_predicate
        RSpec::Matchers::BuiltIn::BePredicate.new(*arguments[:positional])
      end
    end
  end
end
