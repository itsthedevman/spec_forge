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
require "openapi3_parser"
require "pathname"
require "pastel"
require "rspec"
require "sem_version"
require "singleton"
require "thor"
require "webrick"
require "yaml"
require "zeitwerk"

# Require the overwrites
core_ext_path = Pathname.new(__dir__).join("spec_forge", "core_ext")
Dir[core_ext_path.join("**/*.rb")].sort.each { |path| require path }

# Load the files
loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect(
  "cli" => "CLI",
  "http" => "HTTP",
  "openapi" => "OpenAPI"
)

loader.ignore(core_ext_path.to_s)
loader.setup

module SpecForge
  class << self
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

    def blueprints_path
      @blueprints_path ||= forge_path.join("blueprints")
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
  end
end
