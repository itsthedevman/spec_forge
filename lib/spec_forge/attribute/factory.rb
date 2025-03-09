# frozen_string_literal: true

module SpecForge
  class Attribute
    #
    # Represents an attribute that references a factory to generate test data
    #
    # This class allows SpecForge to integrate with FactoryBot for test data generation.
    # It supports various build strategies like create, build, build_stubbed, etc.
    #
    # @example Basic usage in YAML
    #   user: factories.user
    #
    # @example With custom attributes
    #   user:
    #     factories.user:
    #       attributes:
    #         name: "Custom Name"
    #         email: faker.internet.email
    #
    # @example With build strategy
    #   user:
    #     factories.user:
    #       strategy: build
    #       attributes:
    #         admin: true
    #
    # @example With an array of 5 user attributes
    #   user:
    #     factories.user:
    #       strategy: attributes_for
    #       size: 5
    #       attributes:
    #         admin: true
    #
    class Factory < Parameterized
      include Chainable

      #
      # Regular expression pattern that matches attribute keywords with this prefix
      # Used for identifying this attribute type during parsing
      #
      # @return [Regexp]
      #
      KEYWORD_REGEX = /^factories\./i

      #
      # An array of base strategies that can be provided either with or
      # without a size. "stubbed" will automatically be transformed into "build_stubbed"
      #
      # @return [Array<String>]
      #
      BASE_STRATEGIES = %w[
        build
        create
        build_stubbed
        attributes_for
      ].freeze

      # @return [Array<String>] All available build strategies
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
      # Creates a new factory attribute with the specified name and arguments
      #
      # @param ... [Object] Arguments passed from the parent class
      #
      def initialize(...)
        super

        # Check the arguments before preparing them
        arguments[:keyword] = Normalizer.normalize_factory_reference!(arguments[:keyword])

        prepare_arguments!
      end

      #
      # Returns the base object for the variable chain
      #
      # @return [Object] The result of the FactoryBot call
      #
      def base_object
        attributes = arguments[:keyword]

        # Default functionality is to create ("factory.user")
        return FactoryBot.create(factory_name) if attributes.blank?

        build_arguments = construct_factory_parameters(attributes)
        FactoryBot.public_send(*build_arguments)
      end

      private

      #
      # @private
      #
      def construct_factory_parameters(attributes)
        build_strategy, list_size = determine_build_strategy(attributes)

        # This is set up for the base strategies + _pair
        # FactoryBot.<build_strategy>(factory_name, **attributes)
        build_arguments = [
          build_strategy,
          factory_name,
          **attributes[:attributes].resolve_value
        ]

        # Insert the list size after the strategy
        # FactoryBot.<build_strategy>_list(factory_name, list_size, **attributes)
        if build_strategy.end_with?("_list")
          build_arguments.insert(2, list_size)
        end

        build_arguments
      end

      #
      # @private
      #
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
