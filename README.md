# SpecForge

[![Gem Version](https://badge.fury.io/rb/spec_forge.svg)](https://badge.fury.io/rb/spec_forge)
![Ruby Version](https://img.shields.io/badge/ruby-3.2+-ruby)
[![Tests](https://github.com/itsthedevman/spec_forge/actions/workflows/main.yml/badge.svg)](https://github.com/itsthedevman/spec_forge/actions/workflows/main.yml)

Write API tests as sequential workflows in YAML. Generate OpenAPI documentation automatically.

```yaml
# spec_forge/blueprints/users.yml
- name: "Create and verify user"
  request:
    url: /users
    http_verb: POST
    json:
      name: "Jane Smith"
      email: "jane@example.com"
  expect:
  - status: 201
    json:
      shape:
        id: integer
        name: string
        email: string
  store:
    user_id: "{{ response.body.id }}"

- name: "Fetch created user"
  request:
    url: "/users/{{ user_id }}"
  expect:
  - status: 200
    json:
      content:
        name: "Jane Smith"
```

Two steps. One workflow. No Ruby code required.

## Why SpecForge?

**For Testing**
- Write tests the way you think about APIs - as sequences of actions
- Zero boilerplate: no HTTP client setup, no configuration objects
- Full access to RSpec matchers, Faker, and FactoryBot without writing Ruby

**For Documentation**
- Auto-generate OpenAPI specs from your workflows
- Tests ensure documentation always matches your actual API
- View in Swagger UI or Redoc with one command

**For Teams**
- YAML workflows are easier to review than Ruby test code
- QA, developers, and product can all read and contribute
- Version-controlled specifications that live with your code

## Quick Start

```bash
# Install
gem install spec_forge

# Initialize project structure
spec_forge init

# Create your first workflow
spec_forge new blueprint users

# Run it
spec_forge run

# Generate and view documentation
spec_forge serve
```

Visit `http://localhost:8080` to see your API documentation!

## Key Features

- **Step-based workflows**: Tests execute sequentially with explicit variable flow
- **Variable storage**: Capture response values with `store:`, reference them with `{{ variable }}`
- **Validation modes**: Simple `shape:` matching for structure, `schema:` for precise control
- **Tag filtering**: Run subsets with `--tags smoke` or `--skip-tags slow`
- **Lifecycle hooks**: Execute Ruby code at forge, blueprint, or step boundaries
- **Dynamic data**: Built-in Faker and FactoryBot integration
- **Nesting**: Group steps and share configuration with the `shared:` wrapper

## Example: Authentication Flow

```yaml
- name: "Login"
  request:
    url: /auth/login
    http_verb: POST
    json:
      email: "{{ faker.internet.email }}"
      password: "testpass123"
  expect:
  - status: 200
    json:
      shape:
        token: string
  store:
    auth_token: "{{ response.body.token }}"

- name: "Authenticated requests"
  shared:
    request:
      headers:
        Authorization: "Bearer {{ auth_token }}"
  steps:
  - name: "Get profile"
    request:
      url: /me
    expect:
    - status: 200

  - name: "Update profile"
    request:
      url: /me
      http_verb: PUT
      json:
        name: "Updated Name"
    expect:
    - status: 200
```

## When Not to Use SpecForge

Consider alternatives when you need:

1. **Complex Ruby logic** in tests - custom transformations, calculations, or validation beyond matchers
2. **Intricate test setup** - complex database states, multiple service mocks, elaborate fixtures
3. **Non-REST APIs** - GraphQL, gRPC, or WebSocket testing may need specialized tools
4. **Heavy computational testing** - load testing, performance benchmarks, parallel execution

You can use SpecForge alongside traditional RSpec tests. Use SpecForge for standard REST workflows and RSpec for complex scenarios.

## Documentation

For comprehensive guides and reference:

- **[Getting Started](https://github.com/itsthedevman/spec_forge/wiki/Getting-Started)** - Installation and your first workflow
- **[Writing Tests](https://github.com/itsthedevman/spec_forge/wiki/Writing-Tests)** - Complete syntax reference
- **[Configuration](https://github.com/itsthedevman/spec_forge/wiki/Configuration)** - Setup and framework integration
- **[Running Tests](https://github.com/itsthedevman/spec_forge/wiki/Running-Tests)** - CLI commands and filtering
- **[Dynamic Features](https://github.com/itsthedevman/spec_forge/wiki/Dynamic-Features)** - Variables, Faker, FactoryBot
- **[Documentation Generation](https://github.com/itsthedevman/spec_forge/wiki/Documentation-Generation)** - OpenAPI customization

**Upgrading from 0.7?** See the **[Migration Guide](https://github.com/itsthedevman/spec_forge/wiki/Migration-Guide)**.

**API Reference:** [itsthedevman.com/docs/spec_forge](https://itsthedevman.com/docs/spec_forge)

## CLI Reference

| Command | Description |
|---------|-------------|
| `spec_forge init` | Initialize project structure |
| `spec_forge new blueprint <name>` | Create a workflow file |
| `spec_forge new factory <name>` | Create a factory file |
| `spec_forge run` | Execute workflows |
| `spec_forge docs` | Generate OpenAPI specs |
| `spec_forge serve` | Generate and serve documentation |

Run `spec_forge help <command>` for detailed options.

## Contributing

Contributions welcome! See the [Contributing Guide](https://github.com/itsthedevman/spec_forge/wiki/Contributing).

## License

Available as open source under the [MIT License](LICENSE.txt).

## Looking for a Software Engineer?

I'm currently looking for opportunities where I can tackle meaningful problems and help build reliable software while mentoring the next generation of developers. If you're looking for a senior engineer with full-stack Rails expertise and a passion for clean, maintainable code, let's talk!

[bryan@itsthedevman.com](mailto:bryan@itsthedevman.com)