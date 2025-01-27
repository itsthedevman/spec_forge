# frozen_string_literal: true

module SpecForge
  CONFIG_ATTRIBUTES = {
    require_name: {
      description: "Requires if each spec must have a non-blank `name` attribute defined.",
      default: true
    },
    require_description: {
      description: "Requires if each spec must have a non-blank `description` attribute defined.",
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

    def to_yaml
      to_h.join_map("\n") do |key, value|
        config = CONFIG_ATTRIBUTES[key]

        # Convert the individual key/value into yaml
        # ---
        # key: value
        yaml = {key.to_s => value}.to_yaml

        # Description time
        description = config[:description]
        if (default = config[:default]) && !config.nil?
          description += " Defaults to #{default.inspect}"
        end

        # Replace the header with our description comment
        yaml.sub!("---", "# #{description}")
      end
    end
  end
end
