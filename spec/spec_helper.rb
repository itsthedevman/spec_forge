# frozen_string_literal: true

# Set a flag to disable some RSpec overwrites
SPEC_FORGE_INTERNAL_TESTING = true

require "pry"
require "spec_forge"

Dir[SpecForge.root.join("spec/support/**/*.rb")].sort.each { |path| require path }

# See https://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.exclude_pattern = "spec/integration/**/*.rb"

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
    # Reset the config
    SpecForge.instance_variable_set(:@configuration, nil)

    # Remove any factories that were registered
    FactoryBot::Internal.configuration.factories.clear
  end
end

def fixtures_path
  Pathname.new(File.expand_path(".", __dir__)).join("fixtures")
end
