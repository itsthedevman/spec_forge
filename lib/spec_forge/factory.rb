# frozen_string_literal: true

module SpecForge
  class Factory
    #
    # Loads the factories from their yml files and registers them with FactoryBot
    #
    def self.load_and_register
      if SpecForge.configuration.factories.paths?
        FactoryBot.definition_file_paths = SpecForge.configuration.factories.paths
      end

      FactoryBot.find_definitions if SpecForge.configuration.factories.auto_discover?

      factories = load_from_files
      factories.each(&:register)
    end

    #
    # Loads any factories defined in the factories. A single file can contain one or more factories
    #
    # @return [Array<Factory>] An array of factories that were loaded.
    #   Note: This factories have not been registered with FactoryBot.
    #   See #register
    #
    def self.load_from_files
      path = SpecForge.forge_path.join("factories", "**/*.yml")

      factories = []

      Dir[path].each do |file_path|
        hash = YAML.load_file(file_path).deep_symbolize_keys

        hash.each do |factory_name, factory_hash|
          factory_hash[:name] = factory_name

          factories << new(**factory_hash)
        end
      end

      factories
    end

    ############################################################################

    attr_reader :name, :input, :model_class, :variables, :attributes

    #
    # Creates a new Factory
    #
    # @param name [String] The name of the factory
    # @param **input [Hash] Attributes to define the factory. See Normalizer::Factory
    #
    def initialize(name:, **input)
      @name = name
      input = Normalizer.normalize_factory!(input)

      @input = input
      @model_class = input[:model_class]

      @variables = extract_variables(input)
      @attributes = extract_attributes(input)
    end

    #
    # Registers this factory with FactoryBot.
    # Once registered, you can call FactoryBot.build and other methods
    #
    # @return [Self]
    #
    def register
      dsl = FactoryBot::Syntax::Default::DSL.new

      options = {}
      options[:class] = model_class if model_class

      # This creates the factory in FactoryBot
      factory_forge = self
      dsl.factory(name, options) do
        factory_forge.attributes.each do |name, attribute|
          add_attribute(name) { attribute.resolve_value }
        end
      end

      self
    end

    private

    def extract_variables(input)
      variables = Attribute.from(input[:variables])

      # Update the variables that reference other variables lol
      Attribute.bind_variables(variables, variables)
    end

    def extract_attributes(input)
      attributes = Attribute.from(input[:attributes])
      Attribute.bind_variables(attributes, variables)
    end
  end
end
