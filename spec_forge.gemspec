# frozen_string_literal: true

require_relative "lib/spec_forge/version"

Gem::Specification.new do |spec|
  spec.name = "spec_forge"
  spec.version = SpecForge::VERSION
  spec.authors = ["Bryan"]
  spec.email = ["bryan@itsthedevman.com"]

  spec.summary = "Write expressive API tests in YAML with the power of RSpec matchers"
  spec.description = "SpecForge lets you write API tests using a clean YAML syntax while leveraging RSpec's powerful matcher system. It supports dynamic test data generation through Faker, deep variable access, factory integration, and intuitive request/response validation. Reduce boilerplate and focus on what matters - testing your API's behavior."
  spec.homepage = "https://github.com/itsthedevman/spec_forge"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata = {
    "source_code_uri" => "https://github.com/itsthedevman/spec_forge",
    "changelog_uri" => "https://github.com/itsthedevman/spec_forge/blob/main/CHANGELOG.md",
    "bug_tracker_uri" => "https://github.com/itsthedevman/spec_forge/issues",
    "documentation_uri" => "https://github.com/itsthedevman/spec_forge#readme",
    "rubygems_mfa_required" => "true"
  }

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end

  spec.bindir = "bin"
  spec.executables = ["spec_forge"]
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", ">= 6.0"
  spec.add_dependency "commander", "~> 5.0"
  spec.add_dependency "everythingrb", "~> 0.1"
  spec.add_dependency "factory_bot", "~> 6.5"
  spec.add_dependency "faker", "~> 3.5"
  spec.add_dependency "faraday", "~> 2.12"
  spec.add_dependency "mime-types", "~> 3.6"
  spec.add_dependency "rspec", "~> 3.13"
  spec.add_dependency "thor", "~> 1.3"

  # ActiveSupport deprecations for Ruby 3.4
  spec.add_dependency "base64"
  spec.add_dependency "bigdecimal"
  spec.add_dependency "mutex_m"
  ##
end
