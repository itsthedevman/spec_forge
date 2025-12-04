# frozen_string_literal: true

module SpecForge
  class Forge
    class Store < Hash
      def store(key, value)
        super(key.to_sym, value.deep_dup)
      end

      alias_method :remove_all, :except!
    end
  end
end
