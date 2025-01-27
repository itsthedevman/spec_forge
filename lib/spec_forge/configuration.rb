# frozen_string_literal: true

module SpecForge
  CONFIG_ATTRIBUTES = {
    path: {
      description: "The path to where SpecForge stores tests, factories, etc.",
      default: ".spec_forge"
    },
    require_name: {
      description: "Validates that the model has a non-blank name attribute, failing validation if missing or empty",
      default: true
    },
    require_description: {
      description: "Validates that the model has a non-blank description attribute, failing validation if missing or empty",
      default: true
    }
  }.freeze

  class Configuration < Struct.new(*CONFIG_ATTRIBUTES.keys)
    include Singleton

    def self.configure(&)
      instance.configure(&)
    end

    def initialize
      CONFIG_ATTRIBUTES.each do |key, config|
        self[key] = config[:default]
      end
    end

    def configure(&block)
      yield(self) if block
      self
    end

    # Whoever did this was not thinking about the bigger picture
    alias_method :each, :each_pair
  end
end
