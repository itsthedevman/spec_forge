# frozen_string_literal: true

##########################################
# Framework Integration
##########################################

# Rails Integration
# require_relative "../config/environment"

# RSpec Integration (includes your existing configurations)
# require_relative "../spec/spec_helper"

# Custom requires (models, libraries, etc)
# Dir[File.join(__dir__, "..", "lib", "**", "*.rb")].sort.each { |f| require f }

##########################################
# Configuration
##########################################

SpecForge.configure do |config|
  # Base configuration
  config.base_url = "http://localhost:3000"

  # Default request headers
  config.headers = {
    "Authorization" => "Bearer #{ENV.fetch("API_TOKEN", "")}"
  }

  # Optional: Default query parameters
  # config.query = {api_key: ENV['API_KEY']}

  # Factory configuration
  # config.factories.auto_discover = false        # Default: true
  # config.factories.paths += ["lib/factories"]   # Adds to default paths

  # Debug configuration
  # Available in specs with debug: true (aliases: breakpoint, pry)
  # Defaults to printing state overview (-> { puts inspect })
  # Available context: expectation, variables, request, response,
  #                   expected_status, expected_json
  # config.on_debug { binding.pry }

  # Test Framework Configuration
  # Useful for database cleaners, test data setup, etc
  # config.specs.before(:suite) { }
  # config.specs.around { |example| example.run }
  # config.specs.formatter = :documentation
end
