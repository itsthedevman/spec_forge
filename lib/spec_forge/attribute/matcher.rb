# frozen_string_literal: true

module SpecForge
  class Attribute
    class Matcher < Parameterized
      class Methods
        include RSpec::Matchers
      end

      MATCHER_METHODS = Methods.new.freeze
      KEYWORD_REGEX = /^matcher\.|^be\.|^kind_of\./i

      LITERAL_MAPPINGS = {
        "nil" => nil,
        "true" => true,
        "false" => false
      }.freeze

      attr_reader :matcher_method

      #
      # Represents any attribute that is a matcher call.
      #
      #   matcher.<method>
      #   be.<method>
      #   kind_of.<method>
      #
      def initialize(...)
        super

        namespace, method = extract_namespace_and_method

        @matcher_method =
          case namespace
          when "be"
            resolve_be_matcher(method)
          when "kind_of"
            resolve_kind_of_matcher(method)
          else
            resolve_matcher(method)
          end

        prepare_arguments!
      end

      def value
        if uses_positional_arguments?(matcher_method)
          positional = arguments[:positional].resolve.each do |value|
            value.deep_stringify_keys! if value.respond_to?(:deep_stringify_keys!)
          end

          matcher_method.call(*positional)
        elsif uses_keyword_arguments?(matcher_method)
          matcher_method.call(**arguments[:keyword].resolve.deep_stringify_keys)
        else
          matcher_method.call
        end
      end

      private

      def extract_namespace_and_method
        sections = input.split(".", 2)

        if sections.size > 1
          sections[..1]
        else
          [nil, sections.first]
        end
      end

      def resolve_matcher(method_name, namespace: MATCHER_METHODS)
        namespace.public_method(method_name)
      end

      def resolve_be_matcher(method)
        # Resolve any custom matchers
        resolved_matcher =
          case method

          # be.>(*args)
          when "greater_than", "greater"
            resolve_matcher(:>, namespace: MATCHER_METHODS.be)

          # be.>=(*args)
          when "greater_than_or_equal", "greater_or_equal"
            resolve_matcher(:>=, namespace: MATCHER_METHODS.be)

          # be.<(*args)
          when "less_than", "less"
            resolve_matcher(:<, namespace: MATCHER_METHODS.be)

          # be.<=(*args)
          when "less_than_or_equal", "less_or_equal"
            resolve_matcher(:<=, namespace: MATCHER_METHODS.be)

          # be(nil), be(true), be(false)
          when "nil", "true", "false"
            arguments[:positional].insert(0, LITERAL_MAPPINGS[method])
            resolve_matcher(:be)
          end

        # Return the matcher if we found one
        return resolved_matcher if resolved_matcher

        # No matcher found, we're going to assume it's prefixed with "be_"
        resolve_matcher(:"be_#{method}")
      end

      def resolve_kind_of_matcher(method)
        type_class = Object.const_get(method.capitalize)
        arguments[:positional].insert(0, type_class)

        resolve_matcher(:be_kind_of)
      end
    end
  end
end
