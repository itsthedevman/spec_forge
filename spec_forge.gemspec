# frozen_string_literal: true

require_relative "lib/spec_forge/version"

Gem::Specification.new do |spec|
  spec.name = "spec_forge"
  spec.version = SpecForge::VERSION
  spec.authors = ["Bryan"]
  spec.email = ["bryan@itsthedevman.com"]

  spec.summary = "TODO: Write a short summary, because RubyGems requires one."
  spec.description = "TODO: Write a longer description or delete this line."
  spec.homepage = "TODO: Put your gem's website or public repo URL here."
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", ">= 6.0"
  spec.add_dependency "commander", "~> 5.0"
  spec.add_dependency "everythingrb", "~> 0.1"
  spec.add_dependency "factory_bot", "~> 6.5"
  spec.add_dependency "faker", "~> 3.5"
  spec.add_dependency "mime-types", "~> 3.6"
  spec.add_dependency "rspec", "~> 3.13"
  spec.add_dependency "thor", "~> 1.3"

  # ActiveSupport deprecations for Ruby 3.4
  spec.add_dependency "base64"
  spec.add_dependency "bigdecimal"
  spec.add_dependency "mutex_m"
  ##
end
