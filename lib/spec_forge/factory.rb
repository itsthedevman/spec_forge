# frozen_string_literal: true

module SpecForge
  class Factory
    #
    # Loads the factories from their yml files and binds the factory with FactoryBot
    #
    # @param path [String, Path] The base path where the factories directory is located
    #
    def self.load_and_register(base_path)
      FactoryBot.find_definitions if SpecForge.config.factories.auto_discover?

      factories = load_from_path(base_path.join("factories", "**/*.yml"))
      factories.each(&:register)
    end

    #
    # Loads any factories defined in the path. A single file can contain one or more factories
    #
    # @param path [String, Path] The path where the factories are located
    #
    # @return [Array<Factory>] An array of factories that were loaded.
    #   Note: This factories have not been registered with FactoryBot.
    #   See #register
    #
    def self.load_from_path(path)
      factories = []

      Dir[path].map do |file_path|
        hash = YAML.load_file(file_path).deep_symbolize_keys

        hash.each do |factory_name, factory_hash|
          factory_hash[:name] = factory_name

          factories << new(**factory_hash)
        end
      end

      factories
    end

    ############################################################################

    attr_reader :name, :input, :model_class, :attributes

    def initialize(name:, **input)
      @name = name
      input = Normalizer.normalize_factory!(input)

      @input = input
      @model_class = input[:model_class]
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
          add_attribute(name, &attribute.to_proc)
        end
      end

      self
    end

    private

    def extract_attributes(input)
      attributes = Attribute.from(input[:attributes])
      Attribute.update_hash_values(attributes, input[:variables])
    end
  end
end
