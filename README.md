# SpecForge

[![Gem Version](https://badge.fury.io/rb/spec_forge.svg)](https://badge.fury.io/rb/spec_forge)
![Ruby Version](https://img.shields.io/badge/ruby-3.2+-ruby)
[![Tests](https://github.com/itsthedevman/spec_forge/actions/workflows/main.yml/badge.svg)](https://github.com/itsthedevman/spec_forge/actions/workflows/main.yml)

> Note: The code in this repository represents the latest development version with new features and improvements that are being prepared for future releases. For the current stable version, check out [v0.7.1](https://github.com/itsthedevman/spec_forge/releases/tag/v0.7.1) on GitHub releases.

Write API tests as sequential workflows in YAML:

```yaml
# spec_forge/blueprints/users_workflow.yml
- store:
    admin_email: "admin@test.com"
    admin_password: "admin123"

- name: "Login as admin"
  request:
    url: /auth/login
    http_verb: POST
    json:
      email: "{{ admin_email }}"
      password: "{{ admin_password }}"
  expect:
  - status: 200
    json:
      shape:
        token: string
        user:
          id: integer
          email: string
  store:
    auth_token: "{{ response.body.token }}"
    user_id: "{{ response.body.user.id }}"

- name: "Create new user"
  request:
    url: /users
    http_verb: POST
    headers:
      Authorization: "Bearer {{ auth_token }}"
    json:
      name: "{{ faker.name.name }}"
      email: "{{ faker.internet.email }}"
  expect:
  - status: 201
    json:
      shape:
        id: integer
        name: string
        email: string
  store:
    new_user_id: "{{ response.body.id }}"
```

That's a complete workflow that validates your API behavior. Each step runs sequentially, with later steps able to reference values from earlier ones. No Ruby code needed - just clear, executable specifications.

## Why SpecForge?

**For Testing:**

- **Sequential Workflows**: Write tests that mirror how you actually use your API - "First I login, then I create a user, then I verify..."
- **Reduce Boilerplate**: No repetitive setup code or HTTP client configuration
- **Clear Syntax**: YAML that everyone can read and understand, regardless of Ruby expertise
- **Quick Setup**: Start testing APIs in minutes instead of hours

**For Documentation:**

- **OpenAPI Generation**: Generate OpenAPI specifications from your workflows *(early feature - improvements coming based on your feedback!)*
- **Living Documentation**: Your tests ensure the documentation always matches your actual API behavior
- **Professional Output**: View your API docs in Swagger UI or Redoc with minimal setup

**For Teams:**

- **Developer & QA Collaboration**: Create specifications that both developers and QA can maintain
- **Gradual Adoption**: Use alongside your existing test suite, introducing it incrementally

## Key Features

- **Step-Based Workflows**: Write tests as sequential actions that execute top-to-bottom
- **Variable Storage**: Capture values from responses and use them in subsequent steps with `{{ variable }}` syntax
- **Flexible Validation**: Simple mode (`shape`) for everyday testing, advanced mode (`schema`) for edge cases
- **FactoryBot & Faker Integration**: Generate realistic test data without leaving YAML
- **Lifecycle Hooks**: Execute custom Ruby code before/after blueprints or individual steps
- **Tag-Based Filtering**: Organize and selectively run workflows using tags (`--tags smoke`, `--skip-tags slow`)
- **Multiple Verbosity Levels**: From minimal dots to full request/response dumps
- **OpenAPI Generation**: Transform your workflows into OpenAPI specifications (early feature)
- **RSpec Integration**: Leverage all the power of RSpec matchers and expectations

## Quick Start

Get started with SpecForge in 3 commands:

```bash
# 1. Initialize SpecForge
spec_forge init

# 2. Create your first workflow
spec_forge new blueprint users

# 3. Run your workflow
spec_forge run
```

Want to see your API documentation?

```bash
spec_forge serve
```

Then visit `http://localhost:8080` to see your API documentation in Swagger UI!

## When Not to Use SpecForge

Consider alternatives when you need:

1. **Complex Ruby Logic**: If your tests require custom Ruby code for data transformations or validations
2. **Complex Test Setup**: When you need intricate database states or specific service mocks
3. **Custom Response Validation**: For validation logic beyond what matchers provide
4. **Complex Non-JSON Testing**: While SpecForge handles basic XML/HTML responses (coming soon), complex validation might need specialized tools

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

### Initialize Your Project

Create the required directory structure:

```bash
spec_forge init
```

This creates:
- `spec_forge/blueprints/` - Where your workflow files live
- `spec_forge/factories/` - FactoryBot factory definitions (optional)
- `spec_forge/openapi/` - OpenAPI configuration (optional)
- `spec_forge/forge_helper.rb` - Central configuration file

### Create Your First Workflow

Generate a new blueprint with examples:

```bash
spec_forge new blueprint users
```

This creates `spec_forge/blueprints/users.yml` with a complete CRUD workflow example.

### Run Your Workflows

Execute all blueprints:

```bash
spec_forge run
```

Run specific blueprints or use tags:

```bash
spec_forge run users                    # Run users.yml only
spec_forge run --tags smoke             # Run smoke tests only
spec_forge run --tags smoke --verbose   # With detailed output
```

### Generate Documentation

SpecForge can generate OpenAPI specifications from your workflows:

```bash
# Generate OpenAPI specs (smart caching)
spec_forge docs

# Force fresh regeneration
spec_forge docs --fresh

# Generate as JSON instead of YAML
spec_forge docs --format json
```

View your documentation in a browser:

```bash
# Start documentation server
spec_forge serve

# Use Redoc instead of Swagger UI
spec_forge serve --ui redoc

# Custom port
spec_forge serve --port 3001
```

> **Note:** OpenAPI generation is an early feature. The core functionality works as documented, but we're planning improvements based on user feedback. [Share your thoughts!](https://github.com/itsthedevman/spec_forge/issues)

## Example: Complete CRUD Workflow

Here's a realistic example showing sequential workflow execution:

```yaml
# spec_forge/blueprints/posts_workflow.yml
- hook:
    before_blueprint: prepare_database
    after_blueprint: cleanup_database

- store:
    test_email: "test@example.com"
    test_password: "testpass123"

- name: "Register new user"
  request:
    url: /register
    http_verb: POST
    json:
      email: "{{ test_email }}"
      password: "{{ test_password }}"
  expect:
  - status: 201
    json:
      shape:
        message: string

- name: "Login"
  request:
    url: /login
    http_verb: POST
    json:
      email: "{{ test_email }}"
      password: "{{ test_password }}"
  expect:
  - status: 200
    json:
      shape:
        auth_token: string
  store:
    auth_token: "{{ response.body.auth_token }}"

- name: "Authenticated operations"
  request:
    headers:
      Authorization: "Bearer {{ auth_token }}"
  steps:
  - name: "Create post"
    request:
      url: /posts
      http_verb: POST
      json:
        title: "My First Post"
        content: "This is the content"
    expect:
    - status: 201
      json:
        shape:
          id: integer
          title: string
          content: string
    store:
      post_id: "{{ response.body.id }}"

  - name: "Get post"
    request:
      url: "/posts/{{ post_id }}"
      http_verb: GET
    expect:
    - status: 200
      json:
        content:
          id: "{{ post_id }}"
          title: "My First Post"

  - name: "Update post"
    request:
      url: "/posts/{{ post_id }}"
      http_verb: PUT
      json:
        title: "Updated Title"
    expect:
    - status: 200

  - name: "Delete post"
    request:
      url: "/posts/{{ post_id }}"
      http_verb: DELETE
    expect:
    - status: 204
```

This workflow demonstrates:
- **Sequential execution** - Login happens before authenticated operations
- **Variable storage** - Auth token captured and reused
- **Nesting** - Grouped operations with shared headers
- **Realistic data** - Actual email addresses and content
- **Lifecycle hooks** - Database setup/teardown

## Configuration Patterns

### Basic Setup

Configure your API base URL and options in `spec_forge/forge_helper.rb`:

```ruby
SpecForge.configure do |config|
  config.base_url = "http://localhost:3000"
end
```

### Global Variables

Define values that are available across all blueprints:

```ruby
SpecForge.configure do |config|
  config.global_variables = {
    api_version: "v1",
    default_timeout: 30,
    admin_credentials: {
      email: "admin@test.com",
      password: ENV.fetch("ADMIN_PASSWORD", "admin123")
    }
  }
end
```

Then reference them in blueprints:

```yaml
- name: "Login as admin"
  request:
    url: "/{{ api_version }}/auth/login"
    json:
      email: "{{ admin_credentials.email }}"
      password: "{{ admin_credentials.password }}"
```

### Sharing Configuration Across Steps

Instead of global headers (which SpecForge doesn't support), use explicit nesting for better clarity:

```yaml
# ❌ NOT SUPPORTED - Global headers are implicit and hidden
# config.headers = { "Authorization" => "Bearer token" }

# ✅ RECOMMENDED - Explicit and scoped
- name: "Authenticated operations"
  request:
    headers:
      Authorization: "Bearer {{ auth_token }}"
  steps:
  - name: "Create resource"
    request:
      url: /resources
      http_verb: POST
      # Inherits Authorization header

  - name: "Update resource"
    request:
      url: "/resources/{{ resource_id }}"
      http_verb: PUT
      # Also inherits Authorization header
```

This pattern makes it clear which requests have which headers, and keeps your blueprints self-documenting. For more on this approach, see the [Configuration Guide](https://github.com/itsthedevman/spec_forge/wiki/Configuration).

### Lifecycle Hooks

Register callbacks for setup and teardown:

```ruby
SpecForge.configure do |config|
  config.register_callback(:prepare_database) do |context|
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.start
  end

  config.register_callback(:cleanup_database) do |context|
    DatabaseCleaner.clean
  end
end
```

Use them in blueprints:

```yaml
- hook:
    before_blueprint: prepare_database
    after_blueprint: cleanup_database
```

## CLI Commands

### Running Workflows

```bash
# Run all blueprints
spec_forge run

# Run specific blueprint
spec_forge run users_workflow

# Run with tag filtering
spec_forge run --tags smoke
spec_forge run --tags smoke,auth --skip-tags slow

# Run with verbosity
spec_forge run --verbose              # Show all steps
spec_forge run --debug                # Add request/response for failures
spec_forge run --trace                # Show everything
```

### Documentation

```bash
# Generate OpenAPI specs
spec_forge docs
spec_forge docs --fresh
spec_forge docs --format json

# Serve documentation
spec_forge serve
spec_forge serve --ui redoc
spec_forge serve --port 3001
```

### Project Setup

```bash
# Initialize project
spec_forge init
spec_forge init --skip-openapi
spec_forge init --skip-factories

# Generate files
spec_forge new blueprint users
spec_forge new factory user
```

## Documentation

For comprehensive documentation, visit the [SpecForge Wiki](https://github.com/itsthedevman/spec_forge/wiki):

**Getting Started:**
- [Getting Started Guide](https://github.com/itsthedevman/spec_forge/wiki/Getting-Started) - Installation and first workflow
- [Writing Tests](https://github.com/itsthedevman/spec_forge/wiki/Writing-Tests) - Complete workflow structure and syntax
- [Migration Guide](https://github.com/itsthedevman/spec_forge/wiki/Migration-Guide) - Upgrading from 0.7 to 1.0

**Core Features:**
- [Configuration](https://github.com/itsthedevman/spec_forge/wiki/Configuration) - Setup and framework integration
- [Running Tests](https://github.com/itsthedevman/spec_forge/wiki/Running-Tests) - CLI commands and filtering
- [Dynamic Features](https://github.com/itsthedevman/spec_forge/wiki/Dynamic-Features) - Variables, Faker, and data generation

**Advanced Topics:**
- [Callbacks](https://github.com/itsthedevman/spec_forge/wiki/Callbacks) - Lifecycle hooks and custom Ruby integration
- [RSpec Matchers](https://github.com/itsthedevman/spec_forge/wiki/RSpec-Matchers) - Validation and matching
- [Factory Support](https://github.com/itsthedevman/spec_forge/wiki/Factory-Support) - Working with FactoryBot
- [Debugging](https://github.com/itsthedevman/spec_forge/wiki/Debugging) - Troubleshooting techniques

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
