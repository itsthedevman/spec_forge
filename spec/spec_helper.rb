# frozen_string_literal: true

ENV["GEM_ENV"] ||= "development"

require "spec_forge"

# See https://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.disable_monkey_patching!
  config.warnings = true
  config.profile_examples = 3
  config.order = :random

  config.before :each do
    # Remove any factories that were registered
    FactoryBot::Internal.configuration.factories.clear
  end
end
