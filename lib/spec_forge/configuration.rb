# frozen_string_literal: true

module SpecForge
  class Configuration
    class Factories < Struct.new(:auto_discover, :paths)
      attr_predicate :auto_discover, :paths

      def initialize(auto_discover: true, paths: []) = super
    end

    attr_accessor :base_url, :global_variables

    attr_reader :factories, :on_debug_proc, :callbacks

    def initialize
      # Validated
      @base_url = "http://localhost:3000"
      @factories = Factories.new
      @global_variables = {}

      # Internal
      @on_debug_proc = Forge::Debug.default
      @callbacks = {}
    end

    def validate
      output = Normalizer.normalize!(
        {
          base_url: @base_url,
          factories: @factories.to_h,
          global_variables: @global_variables
        },
        using: :configuration
      )

      # In case any value was set to `nil`
      @global_variables = output[:global_variables] if @global_variables.blank?
      @global_variables.symbolize_keys!

      self
    end

    def on_debug(&block)
      @on_debug_proc = block
    end

    def rspec
      RSpec.configuration
    end

    def register_callback(name, &block)
      @callbacks[name.to_sym] = block
    end
  end
end
