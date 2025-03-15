# frozen_string_literal: true

module SpecForge
  class Attribute
    #
    # Represents an attribute that uses RSpec matchers for response validation
    #
    # This class allows SpecForge to integrate with RSpec's powerful matchers
    # for flexible response validation. It supports most of the built-in RSpec matchers
    # and most custom matchers, assuming they do not require more Ruby code
    #
    # @example Basic matchers in YAML
    #   be_true: be.true
    #   include_admin:
    #     matcher.include:
    #     - admin
    #
    # @example Comparison matchers
    #   count:
    #     be.greater_than: 5
    #
    # @example Type checking
    #   name: kind_of.string
    #   id: kind_of.integer
    #
    class Matcher < Parameterized
      #
      # Helper class to access RSpec matcher methods
      #
      class RSpecMatchers
        include RSpec::Matchers
      end

      #
      # Regular expression pattern that matches attribute keywords with this prefix
      # Used for identifying this attribute type during parsing
      #
      # @return [Regexp]
      #
      KEYWORD_REGEX = /^matchers?\.|^be\.|^kind_of\./i

      #
      # Instance of Methods providing access to all RSpec matchers
      #
      MATCHER_METHODS = RSpecMatchers.new.freeze

      #
      # Mapping of literal string values to their Ruby equivalents
      # Used for be.nil, be.true, and be.false matchers
      #
      LITERAL_MAPPINGS = {
        "nil" => nil,
        "true" => true,
        "false" => false
      }.freeze

      #
      # The resolved RSpec matcher method to call
      #
      attr_reader :matcher_method

      #
      # Creates a new matcher attribute with the specified matcher and arguments
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
            resolve_base_matcher(method)
          end

        prepare_arguments!

        # An argument can be an expanded version of something (such as matcher.include)
        # Move it to where it belongs
        if (keyword = arguments[:keyword]) && !Type.hash?(keyword)
          arguments[:positional] << keyword
          arguments[:keyword] = {}
        end
      end

      #
      # Returns the result of applying the matcher with the given arguments
      # Creates an RSpec matcher that can be used in expectations
      #
      # @return [RSpec::Matchers::BuiltIn::BaseMatcher] The configured matcher
      #
      def value
        if (positional = arguments[:positional]) && positional.present?
          positional = positional.resolved.each do |value|
            value.deep_stringify_keys! if value.respond_to?(:deep_stringify_keys!)
          end

          matcher_method.call(*positional)
        elsif (keyword = arguments[:keyword]) && keyword.present?
          matcher_method.call(**keyword.resolved.deep_stringify_keys)
        else
          matcher_method.call
        end
      end

      #
      # Ensures proper conversion of nested matcher arguments based on context
      #
      # This method overrides handles a special case of matchers that take arguments
      # which themselves might need to be converted to matchers. It skips conversion
      # for string arguments that should remain strings
      # (like with include, start_with, and end_with) while correctly handling nested
      # matchers and other argument types.
      #
      # @example Problem case handled
      #   # In YAML:
      #   matcher.all:
      #     matcher.include:
      #     - /@/  # Should become match(/@/) when used with include
      #
      # @example Edge case handled
      #   # In YAML:
      #   matcher.include: "." # Should remain a string, not eq(".")
      #
      # @return [RSpec::Matchers::BuiltIn::BaseMatcher] The properly configured matcher
      #   with all arguments correctly converted based on context
      #
      def resolve_as_matcher
        # Argument conversion only matters for the base matchers
        if input.start_with?("matcher")
          block = lambda do |argument|
            next argument unless convert_argument?(argument)

            argument.resolve_as_matcher
          end

          arguments[:positional].map!(&block)
          arguments[:keyword].transform_values!(&block)
        end

        super
      end

      private

      #
      # Extracts the namespace and method name from the input string
      # For example, "be.empty" would return ["be", "empty"]
      #
      # @return [Array<String, String>] The namespace and method name
      #
      # @private
      #
      def extract_namespace_and_method
        sections = input.split(".", 2)

        if sections.size > 1
          sections[..1]
        else
          [nil, sections.first]
        end
      end

      #
      # Resolves a matcher with the "matcher" prefix
      #
      # @param method [String] The method part after "matcher."
      #
      # @return [Method] The resolved matcher method
      #
      # @private
      #
      def resolve_base_matcher(method)
        if method == "and"
          resolve_matcher("forge_and")
        else
          resolve_matcher(method)
        end
      end

      #
      # Resolves a matcher method by name from the given namespace
      #
      # @param method_name [String, Symbol] The matcher method name
      # @param namespace [Object] The object to resolve the method from
      #
      # @return [Method] The resolved matcher method
      #
      # @private
      #
      def resolve_matcher(method_name, namespace: MATCHER_METHODS)
        if !namespace.respond_to?(method_name)
          raise Error::UndefinedMatcherError, method_name
        end

        namespace.public_method(method_name)
      end

      #
      # Resolves a matcher with the "be" prefix
      # Handles special cases like be.true, be.nil, comparison operators, etc.
      #
      # @param method [String] The method part after "be."
      #
      # @return [Method] The resolved matcher method
      #
      # @private
      #
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

      #
      # Resolves a kind_of matcher for the given type
      # For example, kind_of.string would check if an object is a String
      #
      # @param method [String] The type name to check for
      #
      # @return [Method] The resolved matcher method
      #
      # @private
      #
      def resolve_kind_of_matcher(method)
        type_class = Object.const_get(method.capitalize)
        arguments[:positional].insert(0, type_class)

        resolve_matcher(:be_kind_of)
      end

      #
      # Determines whether an argument should skip conversion to a matcher
      #
      # This helper method handles the case where string arguments to certain matchers
      # (include, start_with, end_with) should remain as strings rather than being
      # converted to eq() matchers.
      #
      # @param argument [Object] The argument to analyze
      #
      # @return [Boolean] true if the argument should skip conversion, false otherwise
      #
      # @example Skip conversion
      #   skip_argument_conversion?(Attribute::Literal.new(".")) #=> true
      #   # When used with include, start_with, or end_with
      #
      # @example Apply conversion
      #   skip_argument_conversion?(Attribute::Regex.new("/@/")) #=> false
      #   # Regex should be converted to match(/@/)
      #
      def convert_argument?(argument)
        return true if argument.is_a?(Attribute::Matcher) || argument.is_a?(Attribute::Regex)

        return true unless [:include, :start_with, :end_with].include?(matcher_method.name)

        resolved = argument.resolved
        resolved.is_a?(Array) || resolved.is_a?(Hash)
      end
    end
  end
end
