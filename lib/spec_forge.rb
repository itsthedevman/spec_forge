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

module SpecForge
  #
  # Loads all factories and specs located in "path", then runs all of the specs
  #
  # @param path [String] The file path that contains factories and specs
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
  # @return [Pathname]
  #
  def self.root
    @root ||= Pathname.pwd
  end

  #
  # Returns SpecForge's working directory
  #
  # @return [Pathname]
  #
  def self.forge_path
    @forge_path ||= root.join("spec_forge")
  end

  #
  # Returns SpecForge's configuration
  #
  # @return [Config]
  #
  def self.configuration
    @configuration ||= Configuration.new
  end

  #
  # Yields SpecForge's configuration to a block
  #
  def self.configure(&block)
    block&.call(configuration)
    configuration
  end

  #
  # Returns a backtrace cleaner configured for SpecForge
  #
  # @return [ActiveSupport::BacktraceCleaner]
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
require_relative "spec_forge/normalizer"
require_relative "spec_forge/runner"
require_relative "spec_forge/spec"
require_relative "spec_forge/type"
require_relative "spec_forge/version"
