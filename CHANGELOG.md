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

## [0.7.0] - 12025-06-22

### Added

#### 🚀 Documentation-First Architecture
**The Big Picture**: SpecForge now generates OpenAPI documentation from your tests automatically!

- **Primary Documentation Workflow**: New `docs` command (now the default!) generates OpenAPI specs from test execution
  - Smart caching system with `--fresh` flag for forced regeneration
  - Multiple output formats: YAML (default) or JSON via `--format`
  - Custom output paths with `--output` option
  - Built-in OpenAPI 3.0.4 validation with detailed, helpful error messages
  - Optional validation skip with `--skip-validation` for faster iterations

- **Live Documentation Server**: `spec_forge serve` command for immediate feedback
  - Local web server with Swagger UI (default) or Redoc (`--ui redoc`)
  - Configurable port with `--port` (defaults to 8080)
  - Auto-generated HTML templates for both UI options
  - Perfect for development and API review workflows

- **Flexible Configuration System**:
  - Directory-based config: `config/components/`, `config/paths/`, etc.
  - Template-based initialization with sensible defaults
  - Enhanced YAML merging with `$ref` support
  - Full OpenAPI customization through configuration files

#### 🧪 Enhanced Testing Capabilities

- **HTTP Header Testing**: Comprehensive header validation
  ```yaml
  headers:
    Content-Type: "application/json"
    X-Request-ID: /^[0-9a-f-]{36}$/
    Cache-Control:
      matcher.and:
      - matcher.include: "max-age="
      - matcher.include: "private"
  ```

- **Flexible Store System**: Store anything, access everything
  - OpenStruct-based entries for maximum flexibility
  - Custom data via callbacks (config, metadata, computed values)
  - Same familiar `store.id.attribute` syntax
  - Perfect for complex test scenarios and feature flags

- **Documentation Control**: Fine-grained control over what gets documented
  - New `documentation: true/false` attribute for specs and expectations
  - Exclude test-only scenarios from API docs while keeping functionality

#### ⚙️ Architecture Improvements

- **YAML-Driven Normalizers**: Configuration over code
  - Structure definitions in `lib/spec_forge/normalizers/*.yml`
  - Powerful `reference:` system for reusable components
  - Wildcard support (`*`) for catch-all schemas
  - Centralized validation logic in dedicated module

- **Enhanced CLI Experience**:
  - Improved `init` command with `--skip-openapi` and `--skip-factories` flags
  - Better help text and examples throughout
  - Clearer error messages with actionable context

- **Developer Utilities**:
  - `Array#to_merged_h` for cleaner hash merging
  - Unified `.normalize!(input, using:)` API across normalizers
  - Separated test preparation (`Runner.prepare`) from execution

### Changed

#### 🎯 User Experience Overhaul

- **New Default Behavior**: `spec_forge` without arguments now shows help instead of running tests
  - **Breaking Change**: Use `spec_forge docs` for documentation or `spec_forge run` for test-only execution
  - Safer default that guides users to the right command for their needs

- **Streamlined Commands**:
  - Better command organization and help text
  - Consistent flag naming across commands
  - Enhanced error handling with helpful suggestions

#### 🏗️ Internal Refactoring

- **Normalizer Architecture**: YAML-based instead of class-heavy approach
  - Consolidated shared definitions in `_shared.yml`
  - Easier maintenance and extension
  - Better error context with attribute path tracking

- **Test Execution Pipeline**:
  - Clean separation between test preparation and execution
  - Enhanced RSpec adapter pattern
  - Better reusability for documentation generation

- **HTTP & Store Improvements**:
  - Automatic header value string conversion
  - Simplified store entry structure with OpenStruct flexibility
  - Enhanced request/response handling

### Removed

- **Legacy Architecture**: Individual normalizer class files (replaced with YAML config)

---

**Migration Notes**:
- Update any scripts using bare `spec_forge` - now shows help instead of running tests
- Use `spec_forge docs` for documentation generation or `spec_forge run` for testing
- Store access patterns remain the same, but internal structure is more flexible

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

[unreleased]: https://github.com/itsthedevman/spec_forge/compare/v0.7.0...HEAD
[0.7.0]: https://github.com/itsthedevman/spec_forge/compare/v0.6.0...v0.7.0
[0.6.0]: https://github.com/itsthedevman/spec_forge/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/itsthedevman/spec_forge/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/itsthedevman/spec_forge/compare/v0.3.2...v0.4.0
[0.3.2]: https://github.com/itsthedevman/spec_forge/compare/v0.3.0...v0.3.2
[0.3.0]: https://github.com/itsthedevman/spec_forge/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/itsthedevman/spec_forge/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/itsthedevman/spec_forge/compare/a8a991c25dcbd472a5fd975e96aa223b05948618...v0.1.0
