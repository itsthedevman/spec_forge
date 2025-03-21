# frozen_string_literal: true

require_relative "../config/environment"
require "database_cleaner/active_record"

SpecForge.configure do |config|
  config.base_url = "http://localhost:3000"

  # Optional: Use documentation formatter for clearer output with callbacks
  config.rspec.formatter = :documentation

  # Configure DatabaseCleaner with RSpec hooks
  exception_tables = {except: %w[api_tokens]}

  config.rspec.before(:suite) do
    DatabaseCleaner.strategy = [:deletion, exception_tables]
    DatabaseCleaner.clean_with(:deletion, exception_tables)
    puts "\n🧪 TEST SUITE STARTED 🧪\n"
  end

  config.rspec.after(:suite) do
    puts "\n🏁 TEST SUITE COMPLETED 🏁\n"
  end

  #============================================================
  # CALLBACK DEFINITIONS
  #============================================================

  # File-level callbacks
  #------------------------------------------------------------
  config.define_callback :log_file_start do |context|
    puts "\n📄 TESTING FILE: #{context.file_name}\n"
  end

  config.define_callback :log_file_end do |context|
    puts "\n✅ COMPLETED FILE: #{context.file_name}\n"
  end

  # Expectation-level callbacks
  #------------------------------------------------------------
  config.define_callback :prepare_database_state do |context|
    # Setup clean database state before each expectation
    DatabaseCleaner.start

    # If this wasn't a demo, we'd skip this print in production
    puts "\n┌─ PREPARING DB"
  end

  config.define_callback :cleanup_database_state do |context|
    # Clean up after each expectation
    DatabaseCleaner.clean

    puts "└─ CLEANED DB AFTER\n"
  end

  # Logging callback with full context
  #------------------------------------------------------------
  config.define_callback :log_context_data do |context|
    # Skip in real usage - this is just to demonstrate available data
    if ENV["DEBUG_CALLBACKS"]
      puts "  ┌─── CONTEXT DATA ───┐"
      puts "  │ File: #{context.file_name}"
      puts "  │ Spec: #{context.spec_name}"
      puts "  │ Test: #{context.expectation_name}"
      puts "  │ URL: #{context.request.url}" if context.respond_to?(:request)
      puts "  └───────────────────┘"
    end
  end

  config.define_callback :log_test_result do |context|
    # This would be where you could log test results,
    # save screenshots, or perform other post-test actions
    if ENV["DEBUG_CALLBACKS"]
      status = context.response&.status
      puts "  RESULT: #{status || "N/A"}"
    end
  end

  # Debugging support
  config.on_debug = -> { binding.pry } # standard:disable Lint/Debugger
end
