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

require_relative "spec_forge/attribute"
require_relative "spec_forge/cli"
require_relative "spec_forge/config"
require_relative "spec_forge/error"
require_relative "spec_forge/factory"
require_relative "spec_forge/http"
require_relative "spec_forge/normalizer"
require_relative "spec_forge/runner"
require_relative "spec_forge/spec"
require_relative "spec_forge/type"
require_relative "spec_forge/version"

module SpecForge
  #
  # Loads all factories and specs located in "path", then runs all of the specs
  #
  # @param path [String] The file path that contains factories and specs
  #
  def self.run(path = SpecForge.forge)
    Factory.load_and_register(path)
    Spec.load_and_run(path)
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
  def self.forge
    @forge ||= root.join("spec_forge")
  end

  #
  # Returns SpecForge's config
  #
  # @return [Config]
  #
  def self.config
    @config ||= Config.new
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
