# frozen_string_literal: true

module SpecForge
  class Attribute
    class Factory < Parameterized
      include Chainable

      KEYWORD_REGEX = /^factories\./i

      BUILD_STRATEGIES = %w[
        build
        create
        attributes_for
        build_stubbed
      ].freeze

      attr_reader :factory_name

      def initialize(...)
        super

        @factory_name = invocation_chain.shift&.to_sym

        # Check the arguments before preparing them
        arguments[:keyword] = Normalizer.normalize_factory_reference!(arguments[:keyword])

        prepare_arguments!
      end

      def value
        @base_object = create_factory_object
        super
      end

      def resolve
        @base_object = create_factory_object
        super
      end

      private

      def create_factory_object
        attributes = arguments[:keyword]
        return FactoryBot.create(@factory_name) if attributes.blank?

        # Determine build strat
        build_strategy = attributes[:build_strategy].resolve

        # stubbed => build_stubbed
        build_strategy.prepend("build_") if build_strategy == "stubbed"
        raise InvalidBuildStrategy, build_strategy unless BUILD_STRATEGIES.include?(build_strategy)

        attributes = attributes[:attributes].resolve
        FactoryBot.public_send(build_strategy, @factory_name, **attributes)
      end
    end
  end
end
