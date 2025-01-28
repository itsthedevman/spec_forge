# frozen_string_literal: true

module SpecForge
  CONFIG_ATTRIBUTES = {
    require_name: {
      description: "Validates that the model has a non-blank name attribute, failing validation if missing or empty.",
      default: true
    },
    require_description: {
      description: "Validates that the model has a non-blank description attribute, failing validation if missing or empty.",
      default: true
    }
  }.freeze

  class Configuration < Struct.new(*CONFIG_ATTRIBUTES.keys)
    include Singleton

    def initialize
      CONFIG_ATTRIBUTES.each do |key, config|
        self[key] = config[:default]
      end
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
        raise "Missing description for \"#{key}\" config attribute" if description.blank?

        if (default = config[:default]) && !config.nil?
          description += " Defaults to #{default.inspect}"
        end

        # Replace the header with our description comment
        yaml.sub!("---", "# #{description}")
      end
    end
  end
end
