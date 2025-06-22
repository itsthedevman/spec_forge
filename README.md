# SpecForge

[![Gem Version](https://badge.fury.io/rb/spec_forge.svg)](https://badge.fury.io/rb/spec_forge)
![Ruby Version](https://img.shields.io/badge/ruby-3.3.7-ruby)
[![Tests](https://github.com/itsthedevman/spec_forge/actions/workflows/main.yml/badge.svg)](https://github.com/itsthedevman/spec_forge/actions/workflows/main.yml)

> Note: The code in this repository represents the latest development version with new features and improvements that are being prepared for future releases. For the current stable version, check out [v0.6.0](https://github.com/itsthedevman/spec_forge/releases/tag/v0.6.0) on GitHub releases.

Write API tests in YAML that read like documentation and generate OpenAPI specifications:

```yaml
show_user:
  path: /users/{id}
  variables:
    expected_status: 200
    user_id: 1
  query:
    id: variables.user_id
  expectations:
  - expect:
      status: variables.expected_status
      json:
        name: kind_of.string
        email:
          matcher.and:
          - kind_of.string
          - /@/
      headers:
        Content-Type: "application/json"
        X-Request-ID: /^[0-9a-f-]{36}$/
```

That's a complete test that validates your API and creates OpenAPI documentation. No Ruby code, no configuration files, no HTTP client setup - just clear, executable specifications.

## Why SpecForge?

**For Testing:**

- **Reduce Boilerplate**: Write tests without repetitive setup code and HTTP configuration
- **Quick Setup**: Start testing APIs in minutes instead of spending hours on test infrastructure
- **Clear Syntax**: Tests that everyone can read and understand, regardless of Ruby expertise

**For Documentation:**

- **OpenAPI Generation**: Generate OpenAPI specifications from your test structure, with full customization through configuration files
- **Living Documentation**: Your tests ensure the documentation always matches your actual API behavior
- **Professional Output**: View your API docs in Swagger UI or Redoc with minimal setup

**For Teams:**

- **Developer & QA Collaboration**: Create specifications that both developers and QA can maintain
- **Gradual Adoption**: Use alongside your existing test suite, introducing it incrementally where it makes sense

## Key Features

- **Automatic Documentation Generation**: Transform tests into OpenAPI specifications with customizable configuration
- **Live Documentation Server**: Local development server for viewing generated documentation
- **YAML-Based Tests**: Write clear, declarative tests that read like documentation
- **RSpec Integration**: Leverage all the power of RSpec matchers and expectations
- **Header Testing**: Comprehensive HTTP header validation with compound matchers
- **FactoryBot Integration**: Generate test data with FactoryBot integration
- **Faker Integration**: Create realistic test data with Faker
- **Variable System**: Define and reference variables for dynamic test data
- **Context Storage**: Store API responses and reference them in subsequent tests
- **Compound Matchers**: Combine multiple validations with `matcher.and` for precise expectations
- **Global Variables**: Define shared configuration at the file level
- **Callback System**: Hook into the test lifecycle using Ruby for setup, teardown, and much more!

## Quick Start

Get started with SpecForge in 3 commands:

```bash
# 1. Initialize SpecForge
spec_forge init

# 2. Create your first test
spec_forge new spec users

# 3. View your documentation
spec_forge serve
```

Then visit `http://localhost:8080` to see your API documentation!

## When Not to Use SpecForge

Consider alternatives when you need:

1. **Complex Ruby Logic**: If your tests require custom Ruby code for data transformations or validations.
2. **Complex Test Setup**: When you need intricate database states or specific service mocks.
3. **Custom Response Validation**: For validation logic beyond what matchers provide.
4. **Complex Non-JSON Testing**: While SpecForge handles basic XML/HTML responses (coming soon), complex validation might need specialized tools.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "spec_forge"
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install spec_forge
```

## Getting Started

Initialize the required directory structure:

```bash
spec_forge init
```

Create your first test:

```bash
spec_forge new spec users
```

Generate documentation (default command):

```bash
spec_forge
```

Or start the live documentation server:

```bash
spec_forge serve
```

Run tests only (no documentation):

```bash
spec_forge run
```

## Documentation Workflow

SpecForge provides multiple ways to work with your API documentation:

```bash
# Generate OpenAPI specifications
spec_forge docs                    # Smart caching
spec_forge docs --fresh            # Force regeneration
spec_forge docs --format json      # Output as JSON instead of YAML

# View documentation in browser
spec_forge serve                   # Generate if needed + serve
spec_forge serve --fresh           # Force regeneration + serve
spec_forge serve --ui redoc        # Use Redoc instead
spec_forge serve --port 3001       # Custom port

# Traditional testing
spec_forge run                     # Pure testing mode
spec_forge run users:show_user     # Run specific tests
```

## Example: Complete User API

```yaml
# spec_forge/specs/users.yml
global:
  variables:
    admin_role: "admin"

list_users:
  path: /users
  expectations:
  - expect:
      status: 200
      headers:
        Content-Type: "application/json"
      json:
        users:
          matcher.have_size:
            be.greater_than: 0

create_user:
  path: /users
  method: POST
  variables:
    username: faker.internet.username
    email: faker.internet.email
  body:
    name: variables.username
    email: variables.email
    role: global.variables.admin_role
  store_as: new_user
  expectations:
  - expect:
      status: 201
      headers:
        Location: /\/users\/\d+/
      json:
        id: kind_of.integer
        name: variables.username
        email: variables.email
        role: global.variables.admin_role

show_user:
  path: /users/{id}
  query:
    id: store.new_user.body.id
  expectations:
  - expect:
      status: 200
      json:
        id: store.new_user.body.id
        name: store.new_user.body.name
        email: store.new_user.body.email
        role: global.variables.admin_role
```

This automatically generates a complete OpenAPI specification with all endpoints, request/response schemas, and examples!

## Documentation

For comprehensive documentation, visit the [SpecForge Wiki](https://github.com/itsthedevman/spec_forge/wiki) which includes:

- [Getting Started Guide](https://github.com/itsthedevman/spec_forge/wiki/Getting-Started)
- [Configuration Options](https://github.com/itsthedevman/spec_forge/wiki/Configuration)
- [Writing Tests](https://github.com/itsthedevman/spec_forge/wiki/Writing-Tests)
- [Running Tests](https://github.com/itsthedevman/spec_forge/wiki/Running-Tests)
- [Debugging Guide](https://github.com/itsthedevman/spec_forge/wiki/Debugging)
- [Dynamic Features](https://github.com/itsthedevman/spec_forge/wiki/Dynamic-Features)
- [Factory Support](https://github.com/itsthedevman/spec_forge/wiki/Factory-Support)
- [RSpec Matchers](https://github.com/itsthedevman/spec_forge/wiki/RSpec-Matchers)

Also see the [API Documentation](https://itsthedevman.com/docs/spec_forge).

## Future Development

For the latest development priorities and feature ideas, check out our [Github Project](https://github.com/itsthedevman/spec_forge/projects?query=is%3Aopen). Have a feature request? Open an issue on GitHub!

## Contributing

Contributions are welcome! See the [Contributing Guide](https://github.com/itsthedevman/spec_forge/wiki/Contributing) for details on how to get started.

## License

The gem is available as open source under the terms of the [MIT License](LICENSE.txt).

## Looking for a Software Engineer?

I'm currently looking for opportunities where I can tackle meaningful problems and help build reliable software while mentoring the next generation of developers. If you're looking for a senior engineer with full-stack Rails expertise and a passion for clean, maintainable code, let's talk!

[bryan@itsthedevman.com](mailto:bryan@itsthedevman.com)
