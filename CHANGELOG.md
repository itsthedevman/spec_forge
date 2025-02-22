# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

### Changed

### Removed

- Removed support for ActiveSupport 7.1 and earlier

## [0.3.2] - 12025-02-20

### Changed

- Moved Regex into its own Attribute class
- Fixed Regex parsing

## [0.3.0] - 12025-02-17

### Added

- Ruby version test matrix

### Changed

- Updated `flake.nix` to use Ruby 3.4

### Removed

- Support for Ruby 3.1

## [0.2.0] - 12025-02-16

### Added

- Core Infrastructure
  - Configuration management
  - User input validation and normalization
  - Factory registration
  - Spec registration and execution
  - Error handling and reporting
  - Multi-level inheritance
  - Debugging tooling

- CLI
  - Project initialization (`init`)
  - Spec/factory generation (`new`)
  - Test execution (`run`)

- Attributes
  - Chainable attribute handling (through `Chainable`)
  - Expanded attribute handling (through `Parameterized`)
  - Factory (with chainable support) - `factories.`
  - Faker (with chainable support) - `faker.`
  - Variable (with chainable support) - `variables.`
  - Literal - `1`, `Some text`, `false`, etc.
  - Matcher - `be`, `kind_of`, `matcher`
  - Transform - `transform.`

- HTTP
  - Configurable HTTP backend through Faraday
  - URL parameter replacement using `{id}` or `:id` syntax
  - Automatic header name transformation

## [0.1.0] - 12025-01-22

- Initial commit

[unreleased]: https://github.com/itsthedevman/spec_forge/compare/v0.3.2...HEAD
[0.3.2]: https://github.com/itsthedevman/spec_forge/compare/v0.3.0...v0.3.2
[0.3.0]: https://github.com/itsthedevman/spec_forge/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/itsthedevman/spec_forge/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/itsthedevman/spec_forge/compare/a8a991c25dcbd472a5fd975e96aa223b05948618...v0.1.0
