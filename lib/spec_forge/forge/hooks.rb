# frozen_string_literal: true

module SpecForge
  class Forge
    class Hooks < Action
      def run(forge)
        puts "hooks run"
      end
    end
  end
end
