# frozen_string_literal: true

module SpecForge
  CONFIG_ATTRIBUTES = {
    base_url: {
      description: "Sets the base URL prefix for all API requests. All test paths will be appended to this URL.",
      default: "http://localhost:3000"
    },
    authorization: {
      description: "Configures the global authorization header and value for API requests.",
      default: {
        default: {
          header: "Authorization",
          value: "Bearer <%= ENV.fetch('API_TOKEN', '') %>"
        }
      }
    }
  }.freeze

  class Configuration < Struct.new(*CONFIG_ATTRIBUTES.keys)
    include Singleton

    def initialize
      load_defaults
    end

    def load_defaults
      CONFIG_ATTRIBUTES.each do |key, config|
        self[key] = config[:default].deep_dup
      end

      # Remove the default ERB for authorization
      # The defaults above are used as an example
      authorization[:default][:value] = ""
    end

    def load_from_file
      path = SpecForge.forge.join("config.yml")
      return unless File.exist?(path)

      erb = ERB.new(File.read(path)).result
      hash = YAML.safe_load(erb, aliases: true, symbolize_names: true)

      CONFIG_ATTRIBUTES.each_key do |key|
        next unless hash.key?(key)

        self[key] = hash[key]
      end
    end

    def to_config_yaml
      CONFIG_ATTRIBUTES.join_map("\n") do |key, config|
        value = config[:default]
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
