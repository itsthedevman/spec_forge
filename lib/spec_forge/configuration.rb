# frozen_string_literal: true

module SpecForge
  #
  # Configuration container for SpecForge settings
  # Defines default values and validation for all configuration options
  #
  class Configuration < Struct.new(:base_url, :headers, :query, :factories, :specs, :on_debug)
    #
    # Manages factory configuration settings
    # Controls auto-discovery behavior and custom factory paths
    #
    # @example
    #   config.factories.auto_discover = false
    #   config.factories.paths += ["lib/factories"]
    #
    class Factories < Struct.new(:auto_discover, :paths)
      #
      # Creates reader methods that return boolean values
      # Allows for checking configuration with predicate methods
      #
      attr_predicate :auto_discover, :paths

      #
      # Initializes a new Factories configuration
      # Sets default values for auto-discovery and paths
      #
      # @param auto_discover [Boolean] Whether to auto-discover factories (default: true)
      # @param paths [Array<String>] Additional paths to look for factories (default: [])
      #
      # @return [Factories] A new factories configuration instance
      #
      def initialize(auto_discover: true, paths: []) = super
    end

    #
    # Overlays options from one hash onto another with special handling for nil values
    # Uses deep_merge with custom logic to handle blank values
    #
    # @param source [Hash] The base hash to overlay onto
    # @param overlay [Hash] The hash containing values to overlay
    #
    # @return [Hash] The merged hash with overlay values taking precedence when appropriate
    #
    def self.overlay_options(source, overlay)
      source.deep_merge(overlay) do |key, source_value, overlay_value|
        # If overlay has a populated value, use it
        if overlay_value.present? || overlay_value == false
          overlay_value
        # If source is nil and overlay exists (but wasn't "present"), use overlay
        elsif source_value.nil? && !overlay_value.nil?
          overlay_value
        # Otherwise keep source value
        else
          source_value
        end
      end
    end

    #
    # Initializes a new Configuration with default values
    # Sets up the configuration structure including factory settings and debug proxy
    #
    # @return [Configuration] A new configuration instance with defaults
    #
    def initialize
      config = Normalizer.default_configuration

      config[:base_url] = "http://localhost:3000"
      config[:factories] = Factories.new
      config[:specs] = RSpec.configuration
      config[:on_debug] = Runner::DebugProxy.default

      super(**config)
    end

    #
    # Validates the configuration and applies normalization
    # Ensures all required fields have values and applies defaults when needed
    #
    # @return [self] Returns self for method chaining
    #
    def validate
      output = Normalizer.normalize_configuration!(to_h)

      # In case any value was set to `nil`
      self.base_url = output[:base_url] if base_url.blank?
      self.query = output[:query] if query.blank?
      self.headers = output[:headers] if headers.blank?

      self
    end

    #
    # Converts the configuration to a hash representation
    # Excludes the specs field and converts nested objects to hashes
    #
    # @return [Hash] Hash representation of the configuration
    #
    def to_h
      hash = super.except(:specs)
      hash[:factories] = hash[:factories].to_h
      hash
    end
  end
end
