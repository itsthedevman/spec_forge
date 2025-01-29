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

require_relative "spec_forge/attribute"
require_relative "spec_forge/cli"
require_relative "spec_forge/configuration"
require_relative "spec_forge/error"
require_relative "spec_forge/factory"
require_relative "spec_forge/spec"
require_relative "spec_forge/version"

module SpecForge
  def self.run(path = ".spec_forge")
    path = root.join(path)

    Factory.load_and_register(path)
    Spec.load_and_run(path)
  end

  def self.root
    Pathname.pwd
  end

  def self.config
    Configuration.instance
  end
end
