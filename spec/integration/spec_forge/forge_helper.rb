# frozen_string_literal: true

require_relative "../config/environment"
require "database_cleaner/active_record"

SpecForge.configure do |config|
  config.base_url = "http://localhost:3000"

  api_token = ApiToken.all.first.token
  config.headers = {
    "Authorization" => "Bearer #{api_token}"
  }

  config.specs.before(:suite) do
    exception_tables = {except: %w[api_tokens]}
    DatabaseCleaner.strategy = [:deletion, exception_tables]
    DatabaseCleaner.clean_with(:deletion, exception_tables)
  end

  config.specs.around do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  config.on_debug = -> { binding.pry }

  config.specs.formatter = :documentation
end
