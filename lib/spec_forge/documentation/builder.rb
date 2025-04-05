# frozen_string_literal: true

module SpecForge
  module Documentation
    class Builder < Hash
      include Singleton

      def self.build(endpoints: [], structures: [])
        instance.load(endpoints:, structures:)
          .group_endpoints
          .combine_endpoints
      end

      def initialize
        @endpoints = []
        @structures = []
      end

      def load(endpoints:, structures:)
        default_proc = ->(hash, key) { hash[key] = {} }

        clear

        self[:info] = {}
        self[:endpoints] = Hash.new(&default_proc)
        self[:structures] = Hash.new(&default_proc)

        @endpoints = endpoints
        @structures = structures

        self
      end

      def group_endpoints
        @endpoints.each do |input|
          # "/users" => {}
          endpoint_hash = self[:endpoints][input[:url]]

          # "GET" => []
          (endpoint_hash[input[:http_verb]] ||= []) << input
        end

        self
      end

      def combine_endpoints
        self[:endpoints].each do |url, operations|
          operations.each do |name, operation|
          end
        end

        self
      end
    end
  end
end
