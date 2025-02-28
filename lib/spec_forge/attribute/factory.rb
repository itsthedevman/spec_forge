# frozen_string_literal: true

module SpecForge
  class Attribute
    class Factory < Parameterized
      include Chainable

      KEYWORD_REGEX = /^factories\./i

      # These are the base strategies that can be provided either with or without size
      # stubbed will be transformed into build_stubbed
      BASE_STRATEGIES = %w[
        build
        create
        build_stubbed
        attributes_for
      ].freeze

      # All available build strategies that are accepted
      BUILD_STRATEGIES = %w[
        attributes_for
        attributes_for_list
        build
        build_list
        build_pair
        build_stubbed
        build_stubbed_list
        create
        create_list
        create_pair
      ].freeze

      alias_method :factory_name, :header

      #
      # Represents any attribute that is a factory reference
      #
      #   factories.<factory_name>
      #
      def initialize(...)
        super

        # Check the arguments before preparing them
        arguments[:keyword] = Normalizer.normalize_factory_reference!(arguments[:keyword])

        prepare_arguments!
      end

      private

      def base_object
        attributes = arguments[:keyword]

        # Default functionality is to create ("factory.user")
        return FactoryBot.create(factory_name) if attributes.blank?

        build_arguments = construct_factory_parameters(attributes)
        FactoryBot.public_send(*build_arguments)
      end

      def construct_factory_parameters(attributes)
        build_strategy, list_size = determine_build_strategy(attributes)

        # This is set up for the base strategies + _pair
        # FactoryBot.create(factory_name, **attributes)
        build_arguments = [
          build_strategy,
          factory_name,
          **attributes[:attributes].resolve_value
        ]

        # Insert the list size after the strategy
        # FactoryBot.create_list(factory_name, list_size, **attributes)
        if build_strategy.end_with?("_list")
          build_arguments.insert(2, list_size)
        end

        build_arguments
      end

      def determine_build_strategy(attributes)
        # Determine build strat, and unfreeze
        build_strategy = +attributes[:build_strategy].resolve_value
        list_size = attributes[:size].resolve_value

        # stubbed => build_stubbed
        build_strategy.prepend("build_") if build_strategy.start_with?("stubbed")

        # create + size => create_list
        # build + size => build_list
        # build_stubbed + size => build_stubbed_list
        # attributes_for + size => attributes_for_list
        if list_size.positive? && BASE_STRATEGIES.include?(build_strategy)
          build_strategy += "_list"
        end

        raise InvalidBuildStrategy, build_strategy unless BUILD_STRATEGIES.include?(build_strategy)

        [build_strategy, list_size]
      end
    end
  end
end
