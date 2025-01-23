# frozen_string_literal: true

require "commander"
require "thor"

require_relative "spec_forge/version"
require_relative "spec_forge/cli"

module SpecForge
  class Error < StandardError; end

  def self.root
    Pathname.pwd
  end
end
