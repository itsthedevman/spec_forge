# frozen_string_literal: true

module SpecForge
  class Forge
    class Expect < Action
      def run(forge)
        step.expects.each do |expect|
          # Build rspec tests
        end
      end
    end
  end
end
