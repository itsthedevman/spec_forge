# frozen_string_literal: true

require "logger"

require "active_support"
require "active_support/core_ext"
require "commander"
require "everythingrb"
require "factory_bot"
require "faker"
require "faraday"
require "mime/types"
require "pathname"
require "rspec"
require "singleton"
require "thor"
require "yaml"

#
# SpecForge: Write expressive API tests in YAML with the power of RSpec matchers
#
# SpecForge is a testing framework that allows writing API tests in a YAML format
# that reads like documentation. It combines the readability of YAML with the
# power of RSpec matchers, Faker data generation, and FactoryBot test objects.
#
# @example Basic spec in YAML
#   get_user:
#     path: /users/1
#     expectations:
#     - expect:
#         status: 200
#         json:
#           name: kind_of.string
#           email: /@/
#
# @example Running specs
#   # Run all specs
#   SpecForge.run
#
#   # Run specific file
#   SpecForge.run(file_name: "users")
#
#   # Run specific spec
#   SpecForge.run(file_name: "users", spec_name: "create_user")
#
module SpecForge
  #
  # Loads all factories and specs and runs the tests with optional filtering
  #
  # This is the main entry point for running SpecForge tests. It loads the
  # forge_helper.rb file if it exists, configures the environment, loads
  # factories and specs, and runs the tests through RSpec.
  #
  # @param file_name [String, nil] Optional name of spec file to run
  # @param spec_name [String, nil] Optional name of spec to run
  # @param expectation_name [String, nil] Optional name of expectation to run
  #
  def self.run(file_name: nil, spec_name: nil, expectation_name: nil)
    path = SpecForge.forge_path

    # Load spec_helper.rb
    forge_helper = path.join("forge_helper.rb")
    require_relative forge_helper if File.exist?(forge_helper)

    # Validate in case anything was changed
    configuration.validate

    # Load factories
    Factory.load_and_register

    # Load the specs from their files and create forges from them
    forges = Loader.load_from_files.map { |f| Forge.new(*f) }

    # Filter out the specs and expectations
    forges = Filter.apply(forges, file_name:, spec_name:, expectation_name:)

    # Define and run everything
    Runner.define(forges)
    Runner.run
  end

  #
  # Returns the directory root for the working directory
  #
  # @return [Pathname] The root directory path
  #
  def self.root
    @root ||= Pathname.pwd
  end

  #
  # Returns SpecForge's working directory
  #
  # @return [Pathname] The spec_forge directory path
  #
  def self.forge_path
    @forge_path ||= root.join("spec_forge")
  end

  #
  # Returns SpecForge's configuration
  #
  # @return [Configuration] The current configuration
  #
  def self.configuration
    @configuration ||= Configuration.new
  end

  #
  # Yields SpecForge's configuration to a block for modification
  #
  # @yield [config] Block that receives the configuration object
  # @yieldparam config [Configuration] The configuration to modify
  #
  # @return [Configuration] The updated configuration
  #
  def self.configure(&block)
    block&.call(configuration)
    configuration
  end

  #
  # Returns a backtrace cleaner configured for SpecForge
  #
  # Creates and configures an ActiveSupport::BacktraceCleaner to improve
  # error messages by removing unnecessary lines and root paths.
  #
  # @return [ActiveSupport::BacktraceCleaner] The configured backtrace cleaner
  #
  def self.backtrace_cleaner
    @backtrace_cleaner ||= begin
      root = "#{SpecForge.root}/"

      cleaner = ActiveSupport::BacktraceCleaner.new
      cleaner.add_filter { |line| line.delete_prefix(root) }
      cleaner.add_silencer { |line| /rubygems|backtrace_cleaner/.match?(line) }
      cleaner
    end
  end

  #
  # Returns the current execution context
  #
  # @return [Context] The current context object
  #
  def self.context
    @context ||= Context.new
  end
end

require_relative "spec_forge/attribute"
require_relative "spec_forge/backtrace_formatter"
require_relative "spec_forge/cli"
require_relative "spec_forge/configuration"
require_relative "spec_forge/context"
require_relative "spec_forge/core_ext"
require_relative "spec_forge/error"
require_relative "spec_forge/factory"
require_relative "spec_forge/filter"
require_relative "spec_forge/forge"
require_relative "spec_forge/http"
require_relative "spec_forge/loader"
require_relative "spec_forge/matchers"
require_relative "spec_forge/normalizer"
require_relative "spec_forge/runner"
require_relative "spec_forge/spec"
require_relative "spec_forge/type"
require_relative "spec_forge/version"
