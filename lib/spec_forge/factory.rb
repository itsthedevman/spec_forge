# frozen_string_literal: true

module SpecForge
  #
  # Manages factory definitions and registration with FactoryBot
  # Provides methods for loading factories from YAML files
  #
  class Factory
    #
    # Loads factories from files and registers them with FactoryBot
    # Sets up paths and loads definitions based on configuration
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
    # Loads factory definitions from YAML files
    # Creates Factory instances but doesn't register them with FactoryBot
    #
    # @return [Array<Factory>] Array of loaded factory instances
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

    # @return [Symbol, String] The name of the factory
    attr_reader :name

    # @return [Hash] The raw input that defined this factory
    attr_reader :input

    # @return [String, nil] The model class name this factory represents, if specified
    attr_reader :model_class

    # @return [Hash<Symbol, Attribute>] Variables defined for this factory
    attr_reader :variables

    # @return [Hash<Symbol, Attribute>] The attributes that define this factory
    attr_reader :attributes

    #
    # Creates a new Factory instance
    #
    # @param name [String, Symbol] The name of the factory
    # @param **input [Hash] The attributes defining the factory
    #
    # @return [Factory] A new factory instance
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
    # Registers this factory with FactoryBot
    # Makes the factory available for use in specs
    #
    # @return [self] Returns self for method chaining
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
