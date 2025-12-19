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

require_path = ->(path) { Dir.glob(path).sort.each { |p| require p } }

# Require the overwrites
root_path = Pathname.new(__dir__)

core_ext_path = root_path.join("spec_forge", "core_ext")
require_path.call(core_ext_path.join("**/*.rb"))

types_path = root_path.join("spec_forge", "types")
require_path.call(types_path.join("**/*.rb"))

# Load the files
loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect(
  "cli" => "CLI",
  "http" => "HTTP",
  "openapi" => "OpenAPI",
  "array_io" => "ArrayIO"
)

# spec_forge/forge/actions/*.rb -> SpecForge::Forge::*
loader.collapse(root_path.join("spec_forge", "forge", "actions"))

# spec_forge/types/*.rb -> SpecForge::*
loader.collapse(types_path)

# Loaded manually above
loader.ignore(core_ext_path)
loader.ignore(types_path)

loader.setup
# loader.eager_load(force: true)

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
