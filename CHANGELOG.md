# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

<!--
## [Unreleased]

### Added

### Changed

### Removed
-->

## [Unreleased]

### Added
- New YAML-based normalizer architecture with structure definitions in `lib/spec_forge/normalizers/`
- Support for structure references with `reference:` keyword for composition
- Dedicated validators module for reusable validation logic

### Changed
- Completely refactored Normalizer class for improved maintainability
  - Moved from class-based to data-driven approach
  - Consolidated shared attributes into `_shared.yml`
  - Added unified public API through `.normalize!(input, using:)` method
- Improved loader error reporting

### Removed
- Individual normalizer class files in favor of YAML configuration

## [0.6.0] - 12025-03-25

### Added

- Added new context system for managing shared state between tests
  - Introduced `SpecForge.context` global accessor for accessing test context
  - Created `Context` class with modular components:
    - `Context::Global` for file-level shared variables
    - `Context::Variables` for managing variables with overlay support
    - `Context::Store` for storing the results of the tests
- Added support for defining and referencing global variables
  ```yaml
  global:
    variables:
      api_version: "v2"
      environment: "test"

  index_user:
    path: "/{api_version}/users"
    query:
      api_version: "global.variables.api_version"
  ```
- Added compound matcher support via `matcher.and` for combining multiple matchers
  ```yaml
  email:
    matcher.and:
    - kind_of.string
    - /@/
    - matcher.end_with: ".com"
  ```
- Added custom RSpec matcher `have_size` for checking an object's size via `matcher.have_size`
- Added new `Loader` class for improved spec file processing
- Added new `Filter` class for more flexible test filtering
- Added normalizer for global context validation
- Added line number tracking for specs and expectations
- Added support for defining and referencing callbacks
  ```ruby
  # Configuration level
  SpecForge.configure do |config|
    config.register_callback("callback_name") { |context| }
    # These are aliases
    # config.define_callback("callback_name") { |context| }
    # config.callback("callback_name") { |context| }
  end

  # Module level (no aliases)
  SpecForge.register_callback("callback_name") { |context| }
  ```
  Once defined, callbacks can be referenced in spec files via the global context
  ```yaml
  global:
    callbacks:
    - before: callback_name
      after: cleanup_database_state
  ```
- Added support for storing and retrieving test data via the `store_as` directive and `store` attribute
  ```yaml
  create_user:
    path: "/users"
    method: "post"
    expectations:
    - variables:
        name: "John"
        email: "john@example.com"
      store_as: "created_user"
      expect:
        status: 200

  show_user:
    path: "/users/:id"
    query:
      id: store.created_user.response.id
    - expect:
        status: 200
  ```
- Added `UndefinedMatcherError` for clearer error messaging when invalid matchers are used
- Enhanced debugging capabilities with improved DebugProxy methods and store access
- Added HTTP status descriptions for better error messages
- Added support for string values in `query`, `body`, and `variables` attributes
- Added print statement when filtering tests for better visibility

### Changed

- Renamed `SpecForge.forge` to `SpecForge.forge_path`
- Renamed attribute `http_method` to `http_verb` (`http_method` is now an alias)
- Refactored attribute resolution methods:
  - Renamed `Attribute#resolve` to `#resolved` (memoized version)
  - Renamed `Attribute#resolve_value` to `#resolve` (immediate resolution)
  - Added `Attribute#resolve_as_matcher` for resolving attributes into RSpec matchers
- Refactored variable resolution to use the new context system
- Updated `Runner` to properly initialize and manage context between tests
- Improved error messages with more contextual information about the execution environment
- Updated YARD comments with better API descriptions and examples
- Restructured internal architecture for better separation of concerns
- Moved all error classes under `SpecForge::Error`
- Fixed issue where nesting expanded matchers (such as `matcher.include`) would cause an error
- Improved response body validation for hash expectations:
  - Each root-level key is now checked individually for more precise error messages
  - Nested hashes still use the `include` matcher for flexibility
- Adjusted `Attribute::Matcher` to accept either `matcher` or `matchers` namespace
- Changed empty array matcher from using `contain_exactly` to `eq([])`
- Changed empty hash matcher from using `include` to `eq({})`
- Changed `forge_and` description from "matches all of:" to "match all:"
- Improved error handling for chainable attributes with better descriptions for various object types
- Limited error backtrace to 50 lines for cleaner output
- Enhanced spec loading error messages with more detailed information
- Improved RSpec example descriptions for better test output
- Added support for overwriting headers at the request level

## Removed

- Removed `Configuration.overlay_options`

## [0.5.0] - 12025-02-28

### Added

- Added support for testing array responses via `json`
- Added check to block RSpec overwrites from running with internal tests
- Added debugging access to `expected_json_class` variable.
- Added support for FactoryBot list strategies through the new `size` attribute
  ```yaml
  variables:
    users:
      factory.user:
        size: 10  # Creates 10 user records
  ```
  - All FactoryBot list methods now supported:
    - `create_list` (default)
    - `build_list`
    - `build_stubbed_list`
    - `attributes_for_list`
    - `build_pair`
    - `create_pair`
  - Comprehensive documentation available in the [Factory Lists wiki](https://github.com/itsthedevman/spec_forge/wiki/Factory-Lists)

### Changed

- Updated `Constraint` to use `include` for testing Hashes and `contains_exactly` for testing Arrays
- Better handling of positional and keyword argument passing for `Matcher` and `Faker` attributes

## [0.4.0] - 12025-02-22

### Added

- Added support to run an individual file, spec, or expectation

### Changed

- Updated `everythingrb` to 0.2
- Updated spec and factory templates
- Improved error reporting to use SpecForge's commands instead of RSpec's
- Updated `run` command's CLI documentation

### Removed

- Removed support for ActiveSupport 7.0

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

[unreleased]: https://github.com/itsthedevman/spec_forge/compare/v0.6.0...HEAD
[0.6.0]: https://github.com/itsthedevman/spec_forge/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/itsthedevman/spec_forge/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/itsthedevman/spec_forge/compare/v0.3.2...v0.4.0
[0.3.2]: https://github.com/itsthedevman/spec_forge/compare/v0.3.0...v0.3.2
[0.3.0]: https://github.com/itsthedevman/spec_forge/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/itsthedevman/spec_forge/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/itsthedevman/spec_forge/compare/a8a991c25dcbd472a5fd975e96aa223b05948618...v0.1.0
