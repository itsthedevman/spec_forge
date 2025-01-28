# frozen_string_literal: true

require_relative "factory/definition_proxy"

module SpecForge
  class Factory
    #
    # Loads the factories from their yml files and binds the factory with FactoryBot
    #
    # @param path [String, Path] The base path where the factories directory is located
    #
    def self.load_and_register(base_path)
      factories = load_from_path(base_path.join("factories", "**/*.yml"))
      factories.each(&:register_with_factory_bot)
    end

    #
    # Loads any factories defined in the path. A single file can contain one or more factories
    #
    # @param path [String, Path] The path where the factories are located
    #
    # @return [Array<Factory>] An array of factories that were loaded.
    #   Note: This factories have not been registered with FactoryBot.
    #   See #register_with_factory_bot
    #
    def self.load_from_path(path)
      factories = []

      Dir[path].map do |file_path|
        hash = YAML.load_file(file_path).deep_symbolize_keys

        hash.each do |factory_name, factory_hash|
          factory_hash[:name] = factory_name
          factory_hash[:model_class] = factory_hash.delete(:class)

          factories << new(**factory_hash)
        end
      end

      factories
    end

    ############################################################################

    attr_reader :name, :model_class

    def initialize(name:, model_class: nil, attributes: {})
      @name = name
      @model_class = model_class
      @attributes = attributes
    end

    def attributes
      @attributes.to_h.transform_values! do |value|
        Attribute.from(value)
      end
    end

    #
    # Registers this factory with FactoryBot.
    # Once registered, you can call FactoryBot.build and other methods
    #
    # @return [Self]
    #
    def register_with_factory_bot
      dsl = FactoryBot::Syntax::Default::DSL.new

      options = {}
      options[:class] = model_class if model_class

      # This allows us to use this class within FactoryBot::DefinitionProxy
      DefinitionProxy.prepare(self)

      # This lambda will be called via instance_eval on FactoryBot::DefinitionProxy
      # self is not this class
      factory_definition = ->(_) { SpecForge::Factory::DefinitionProxy.define(self) }

      # This creates the factory in FactoryBot
      dsl.factory(name, options, &factory_definition)

      self
    ensure
      DefinitionProxy.reset
    end
  end
end
