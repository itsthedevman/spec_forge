# frozen_string_literal: true

require "logger"

require "active_support"
require "active_support/core_ext"
require "commander"
require "everythingrb/prelude"
require "everythingrb/all"
require "factory_bot"
require "faker"
require "faraday"
require "mime/types"
require "pathname"
require "rspec"
require "sem_version"
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
  class << self
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
    def run(file_name: nil, spec_name: nil, expectation_name: nil)
      forges = Runner.prepare(file_name:, spec_name:, expectation_name:)
      Runner.run(forges, exit_on_finish: true)
    end

    #
    # Returns the directory root for the working directory
    #
    # @return [Pathname] The root directory path
    #
    def root
      @root ||= Pathname.pwd
    end

    #
    # Returns SpecForge's working directory
    #
    # @return [Pathname] The spec_forge directory path
    #
    def forge_path
      @forge_path ||= root.join("spec_forge")
    end

    #
    # Returns SpecForge's openapi directory
    #
    # @return [Pathname] The spec_forge openapi directory path
    #
    def openapi_path
      @openapi_path ||= forge_path.join("openapi")
    end

    #
    # Returns SpecForge's configuration
    #
    # @return [Configuration] The current configuration
    #
    def configuration
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
    def configure(&block)
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
    def backtrace_cleaner
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
    def context
      @context ||= Context.new
    end

    #
    # Registers a callback for a specific test lifecycle event
    # Allows custom code execution at specific points during test execution
    #
    # @param name [Symbol, String] A unique identifier for this callback
    # @yield A block to execute when the callback is triggered
    # @yieldparam context [Object] An object containing context-specific state data, depending
    #   on which hook the callback is triggered from.
    #
    # @return [Proc] The registered callback
    #
    # @example Registering a custom debug handler
    #   SpecForge.register_callback(:clean_database) do |context|
    #     DatabaseCleaner.clean
    #   end
    #
    def register_callback(name, &)
      Callbacks.register(name, &)
    end

    #
    # Generates a unique ID for an object based on hash and object_id
    #
    # @param object [Object] The object to generate an ID for
    #
    # @return [String] A unique ID string
    #
    # @private
    #
    def generate_id(object)
      "#{object.hash.abs.to_s(36)}_#{object.object_id.to_s(36)}"
    end
  end
end

require_relative "spec_forge/attribute"
require_relative "spec_forge/backtrace_formatter"
require_relative "spec_forge/callbacks"
require_relative "spec_forge/cli"
require_relative "spec_forge/configuration"
require_relative "spec_forge/context"
require_relative "spec_forge/core_ext"
require_relative "spec_forge/documentation"
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
