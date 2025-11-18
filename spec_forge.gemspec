# frozen_string_literal: true

require_relative "lib/spec_forge/version"

Gem::Specification.new do |spec|
  spec.name = "spec_forge"
  spec.version = SpecForge::VERSION
  spec.authors = ["Bryan"]
  spec.email = ["bryan@itsthedevman.com"]

  spec.summary = "Write expressive API tests in YAML with the power of RSpec matchers"
  spec.description = "Write API tests in YAML without sacrificing power. SpecForge combines RSpec's matcher system, Faker's data generation, and factory patterns into a clean, declarative syntax that eliminates boilerplate while preserving control over your test suite."
  spec.homepage = "https://github.com/itsthedevman/spec_forge"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

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

  spec.add_dependency "activesupport", ">= 6.1"
  spec.add_dependency "commander", "~> 5.0"
  spec.add_dependency "everythingrb", "~> 0.8"
  spec.add_dependency "factory_bot", "~> 6.5"
  spec.add_dependency "faker", "~> 3.5"
  spec.add_dependency "faraday", "~> 2.12"
  spec.add_dependency "mime-types", "~> 3.6"
  spec.add_dependency "openapi3_parser", "~> 0.10.1"
  spec.add_dependency "rspec", "~> 3.13"
  spec.add_dependency "sem_version", "~> 2.0"
  spec.add_dependency "thor", "~> 1.3"
  spec.add_dependency "webrick", "~> 1.9"
  spec.add_dependency "zeitwerk", "~> 2.7"
end
