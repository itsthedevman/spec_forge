# frozen_string_literal: true

module SpecForge
  class Configuration < Struct.new(:base_url, :headers, :query, :factories, :specs)
    ############################################################################

    class Factories < Struct.new(:auto_discover, :paths)
      attr_predicate :auto_discover, :paths

      def initialize(auto_discover: true, paths: []) = super
    end

    ############################################################################

    def initialize
      config = Normalizer.default_configuration

      config[:base_url] = "http://localhost:3000"
      config[:factories] = Factories.new
      config[:specs] = RSpec.configuration

      super(**config)
    end

    def validate
      output = Normalizer.normalize_configuration!(to_h)

      # In case any value was set to `nil`
      self.base_url = output[:base_url]
      self.query = output[:query]
      self.headers = output[:headers]
      self.factories = Factories.new(**output[:factories])

      self
    end

    def to_h
      hash = super.except(:specs)
      hash[:factories] = hash[:factories].to_h
      hash
    end
  end
end
