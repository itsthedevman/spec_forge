# frozen_string_literal: true

module SpecForge
  CONFIG_ATTRIBUTES = {
    require_name: {
      description: "Validates that each spec has a non-blank name attribute, failing validation if missing or empty.",
      default: true
    },
    require_description: {
      description: "Validates that each spec has a non-blank description attribute, failing validation if missing or empty.",
      default: true
    },
    authorization: {
      description: "Configures the global authorization header and value for API requests.",
      default: {
        default: {
          header: "Authorization",
          value: "Bearer <%= ENV.fetch('API_TOKEN') %>"
        }
      }
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
        value = value.deep_stringify_keys if value.is_a?(Hash)

        # Convert the individual key/value into yaml
        # ---
        # key: value
        yaml = {key.to_s => value}.to_yaml

        # Description time
        description = config[:description]
        raise "Missing description for \"#{key}\" config attribute" if description.blank?

        # Replace the header with our description comment
        yaml.sub!("---", "# #{description}")
      end
    end
  end
end
