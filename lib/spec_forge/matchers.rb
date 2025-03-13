# frozen_string_literal: true

module SpecForge
  class Matchers
    include Singleton

    def self.define
      instance.define_all
    end

    def define_all
      define_forge_and
    end

    private

    def define_forge_and
      RSpec::Matchers.define :forge_and do |*matchers|
        match do |actual|
          @failures = []

          matchers.each do |matcher|
            next if matcher.matches?(actual)

            @failures << [matcher, matcher.failure_message]
          end

          @failures.empty?
        end

        failure_message do
          pass_count = matchers.size - @failures.size

          message = "Expected to satisfy ALL of these conditions on:\n   #{actual.inspect}\n\n"

          matchers.each_with_index do |matcher, i|
            failure = @failures.find { |m, _| m == matcher }

            if failure
              message += "❌ #{i + 1}. #{matcher.description}\n"
              message += "      → #{failure[1].gsub(/\s+/, " ").strip}\n\n"
            else
              message += "✅ #{i + 1}. #{matcher.description}\n\n"
            end
          end

          message += "#{pass_count}/#{matchers.size} conditions met"
          message
        end

        description do
          "matches all of: " + matchers.join_map(", ", &:description)
        end
      end
    end
  end
end
