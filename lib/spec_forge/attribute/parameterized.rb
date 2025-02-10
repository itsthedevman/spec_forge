# frozen_string_literal: true

module SpecForge
  class Attribute
    class Parameterized < Attribute
      def self.from_hash(hash)
        metadata = hash.first

        input = metadata.first
        arguments = metadata.second

        case arguments
        when ArrayLike
          new(input, arguments)
        when HashLike
          # Offset for positional arguments. No support for both at this time
          new(input, [], arguments)
        else
          # Single value
          new(input, [arguments])
        end
      end

      attr_reader :arguments

      def initialize(input, positional = [], keyword = {})
        super(input.to_s.downcase)

        @arguments = Attribute.from(positional:, keyword:)
      end

      def bind_variables(variables)
        arguments[:positional].each { |v| Attribute.bind_variables(v, variables) }
        arguments[:keyword].each_value { |v| Attribute.bind_variables(v, variables) }
      end

      protected

      def uses_positional_arguments?(method)
        method.parameters.any? { |a| [:req, :opt, :rest].include?(a.first) }
      end

      def uses_keyword_arguments?(method)
        method.parameters.any? { |a| [:keyreq, :key, :keyrest].include?(a.first) }
      end
    end
  end
end
