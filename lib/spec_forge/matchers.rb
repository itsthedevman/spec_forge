# frozen_string_literal: true

module SpecForge
  #
  # Provides custom RSpec matchers for SpecForge
  #
  # This singleton class is responsible for defining custom RSpec matchers
  # that can be used in SpecForge tests. It makes these matchers available
  # through RSpec's matcher system.
  #
  # @example Defining all matchers
  #   SpecForge::Matchers.define
  #
  class Matchers
    include Singleton

    #
    # Defines all custom matchers for use in SpecForge tests
    #
    # This is the main entry point that should be called once during
    # initialization to make all custom matchers available.
    #
    def self.define
      instance.define_all
    end

    #
    # Defines all available custom matchers
    #
    # This method calls individual definition methods for each
    # custom matcher supported by SpecForge.
    #
    def define_all
      define_forge_and
      define_have_size
    end

    private

    #
    # Defines the forge_and matcher for combining multiple matchers.
    # Explicitly has "forge_" prefix to avoid potentially clashing with someone's
    # existing custom matchers.
    #
    # This matcher allows chaining multiple matchers together with an AND
    # condition, requiring all matchers to pass. It provides detailed
    # failure messages showing which specific matchers failed.
    #
    # @example Using forge_and in a test
    #   expect(response.body).to forge_and(
    #     have_key("name"),
    #     have_key("email"),
    #     include("active" => be_truthy)
    #   )
    #
    # @private
    #
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
          "match all: " + matchers.join_map(", ", &:description)
        end
      end
    end

    #
    # Defines the have_size matcher for checking collection sizes
    #
    # This matcher verifies that an object responds to the :size method
    # and that its size matches the expected value.
    #
    # @example Using have_size in a test
    #   expect(response.body["items"]).to have_size(5)
    #
    # @private
    #
    def define_have_size
      RSpec::Matchers.define :have_size do |expected|
        expected = RSpec::Matchers::BuiltIn::Eq.new(expected) if expected.is_a?(Integer)

        match do |actual|
          actual.respond_to?(:size) && expected.matches?(actual.size)
        end

        failure_message do |actual|
          if actual.respond_to?(:size)
            "expected #{actual.inspect} size to #{expected.description}, but got #{actual.size}"
          else
            "expected #{actual.inspect} to respond to :size"
          end
        end
      end
    end
  end
end

# Define the custom matchers
SpecForge::Matchers.define
