# frozen_string_literal: true

module SpecForge
  class Factory
    class DefinitionProxy
      include Singleton

      #
      # Stores the provided factory to be accessed later
      #
      # @param factory [Factory]
      #
      def self.prepare(factory)
        instance.factory = factory
      end

      #
      # Runs the various FactoryBot definition methods to configure a factory
      #
      # @param proxy [FactoryBot::DefinitionProxy]
      #
      def self.define(proxy)
        factory = instance.factory

        factory.attributes.to_h.each do |name, value|
          proxy.add_attribute(name) { value }
        end
      end

      #
      # Returns the proxy back to its original state
      #
      def self.reset
        instance.factory = nil
      end

      ##################################

      # The underlying factory this proxy is for
      attr_accessor :factory
    end
  end
end
