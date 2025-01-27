# frozen_string_literal: true

require "commander"
require "singleton"
require "thor"

env = ENV["GEM_ENV"] || ENV["RAILS_ENV"] || ENV["RACK_ENV"]
require "pry" if env == "development"

require_relative "spec_forge/version"
require_relative "spec_forge/cli"
require_relative "spec_forge/configuration"

module SpecForge
  class Error < StandardError; end

  def self.root
    Pathname.pwd
  end

  def self.configuration
    Configuration.instance
  end

  def self.configure(&)
    Configuration.configure(&)
  end
end
