# frozen_string_literal: true

## Using Rails? Uncomment to load your app
# ENV["RAILS_ENV"] ||= "test"
# require_relative "../config/environment"

## Not using Rails? Load anything you need here
# Dir[SpecForge.root.join("lib", "my_api", "models", "**/*.rb")].sort.each { |path| require path }

## Using RSpec? Uncomment to use your existing configurations
# require_relative "../spec/spec_helper"

SpecForge.configure do |config|
  ## Base URL prefix for all API requests. All test paths will be appended to this URL
  config.base_url = "http://localhost:3000"

  ## Default request headers - commonly used for authentication and content negotiation
  api_token = ENV.fetch("API_TOKEN", "")
  config.headers = {
    "Authorization" => "Bearer #{api_token}"
  }

  ## Default query parameters - useful for API keys or additional request context
  # config.query = {api_token:}

  ## Factory configuration options
  ##
  ## Enable/disable automatic factory discovery. When enabled, SpecForge will automatically
  ## load factories from FactoryBot's default paths. Note: Factories defined in
  ## "spec_forge/factories" are always loaded regardless of this setting.
  # config.factories.auto_discover = false  # Default: true

  ##
  ## Additional paths, relative to the project folder, for discovering FactoryBot factories
  ## By default, FactoryBot looks in "spec/factories" and "test/factories"
  # config.factories.paths += ["custom/factories/path"]
end
