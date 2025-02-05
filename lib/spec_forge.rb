# frozen_string_literal: true

env = ENV["GEM_ENV"] || ENV["RAILS_ENV"] || ENV["RACK_ENV"]
require "pry" if env == "development"

################################################################################

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
require_relative "spec_forge/configuration"
require_relative "spec_forge/error"
require_relative "spec_forge/factory"
require_relative "spec_forge/http"
require_relative "spec_forge/normalizer"
require_relative "spec_forge/runner"
require_relative "spec_forge/spec"
require_relative "spec_forge/version"

module SpecForge
  def self.run(path = forge)
    config.load_from_file

    Factory.load_and_register(path)
    Spec.load_and_run(path)
  end

  def self.root
    @root ||= Pathname.pwd
  end

  def self.forge
    @forge ||= root.join(".spec_forge")
  end

  def self.config
    Configuration.instance
  end

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
