# frozen_string_literal: true

source "https://rubygems.org"

gem "rails", "~> 8.0"

# Specify your gem's dependencies in spec_forge.gemspec
gemspec

gem "rake", "~> 13.0"

gem "standard", "~> 1.49"

gem "pry"

gem "benchmark-ips", "~> 2.14"

group :test do
  gem "simplecov", require: false
  gem "sinatra"
  gem "net-http", "~> 0.5.0"  # Pin to 0.5.x for compatibility with faraday-net_http
end

gem "ruby-lsp", require: false

group :development, :documentation do
  gem "yard"
  gem "kramdown"
  gem "puma"
end
