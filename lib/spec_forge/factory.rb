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
    # Factory names are derived from the filename (e.g., user.yml -> :user)
    #
    # @return [Array<Factory>] Array of loaded factory instances
    #
    def self.load_from_files
      path = SpecForge.forge_path.join("factories", "**/*.yml")

      factories = []

      Dir[path].each do |file_path|
        hash = YAML.load_file(file_path, symbolize_names: true)

        # Extract factory name from filename (e.g., "user.yml" -> :user)
        factory_name = File.basename(file_path, ".yml").to_sym
        hash[:name] = factory_name

        factories << new(**hash)
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

    # @return [Hash<Symbol, Hash<Symbol, Attribute>>] Traits defined for this factory
    attr_reader :traits

    #
    # Creates a new Factory instance
    #
    # @param name [String, Symbol] The name of the factory
    # @param input [Hash] The attributes defining the factory
    #
    # @return [Factory] A new factory instance
    #
    def initialize(name:, **input)
      @name = name
      input = Normalizer.normalize!(input, using: :factory)

      @input = input
      @model_class = input[:model_class]

      @variables = Attribute.from(input[:variables])
      @attributes = Attribute.from(input[:attributes])
      @traits = extract_traits(input[:traits])
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
      options[:class] = model_class if model_class.present?

      # This creates the factory in FactoryBot
      factory_forge = self
      dsl.factory(name, options) do
        # Register base attributes
        factory_forge.attributes.each do |attr_name, attribute|
          add_attribute(attr_name) { attribute.resolve }
        end

        # Register traits
        factory_forge.traits.each do |trait_name, trait_attributes|
          trait(trait_name) do
            trait_attributes.each do |attr_name, attribute|
              add_attribute(attr_name) { attribute.resolve }
            end
          end
        end
      end

      self
    end

    private

    #
    # Extracts and processes trait definitions from the input hash
    # Trait definitions are flat hashes of attributes (no nested "attributes:" key)
    #
    # @param traits_hash [Hash] Raw trait definitions from YAML
    # @return [Hash<Symbol, Hash<Symbol, Attribute>>] Processed traits with Attribute values
    #
    def extract_traits(traits_hash)
      return {} if traits_hash.blank?

      traits_hash.transform_values do |trait_attributes|
        Attribute.from(trait_attributes || {})
      end
    end
  end
end
