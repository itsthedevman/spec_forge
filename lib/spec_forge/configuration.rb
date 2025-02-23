# frozen_string_literal: true

module SpecForge
  class Configuration < Struct.new(:base_url, :headers, :query, :factories, :specs, :on_debug)
    ############################################################################

    class Factories < Struct.new(:auto_discover, :paths)
      attr_predicate :auto_discover, :paths

      def initialize(auto_discover: true, paths: []) = super
    end

    ############################################################################

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

    def initialize
      config = Normalizer.default_configuration

      # Allows me to modify the error backtrace reporting within rspec
      RSpec.configuration.instance_variable_set(:@backtrace_formatter, BacktraceFormatter)

      config[:base_url] = "http://localhost:3000"
      config[:factories] = Factories.new
      config[:specs] = RSpec.configuration
      config[:on_debug] = Runner::DebugProxy.default

      super(**config)
    end

    def validate
      output = Normalizer.normalize_configuration!(to_h)

      # In case any value was set to `nil`
      self.base_url = output[:base_url] if base_url.blank?
      self.query = output[:query] if query.blank?
      self.headers = output[:headers] if headers.blank?

      self
    end

    def to_h
      hash = super.except(:specs)
      hash[:factories] = hash[:factories].to_h
      hash
    end
  end
end
