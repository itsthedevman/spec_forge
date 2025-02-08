# frozen_string_literal: true

module SpecForge
  class Attribute
    class Factory < Parameterized
      include Chainable

      KEYWORD_REGEX = /^factories\./i

      attr_reader :factory_name

      def initialize(...)
        super

        @factory_name = invocation_chain.shift&.to_sym
      end

      def value
        @base_object = create_factory_object
        super
      end

      private

      def create_factory_object
        FactoryBot.create(@factory_name)
      end
    end
  end
end
