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
require "pathname"
require "singleton"
require "thor"
require "yaml"

require_relative "spec_forge/version"
require_relative "spec_forge/cli"
require_relative "spec_forge/configuration"
require_relative "spec_forge/factory"

module SpecForge
  class Error < StandardError; end

  def self.run(path = ".spec_forge")
    path = root.join(path)

    Factory.load_and_register(path)
  end

  def self.root
    Pathname.pwd
  end

  def self.config
    Configuration.instance
  end
end
