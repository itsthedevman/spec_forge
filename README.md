# SpecForge

[![Gem Version](https://badge.fury.io/rb/spec_forge.svg)](https://badge.fury.io/rb/spec_forge)
![Ruby Version](https://img.shields.io/badge/ruby-3.3.7-ruby)
[![Tests](https://github.com/itsthedevman/spec_forge/actions/workflows/main.yml/badge.svg)](https://github.com/itsthedevman/spec_forge/actions/workflows/main.yml)

> Note: The code in this repository represents the latest development version with new features and improvements that are being prepared for future releases. For the current stable version, check out [v0.5.0](https://github.com/itsthedevman/spec_forge/releases/tag/v0.5.0) on GitHub releases.

Write API tests in YAML that read like documentation:

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
```

That's a complete test. No Ruby code, no configuration files, no HTTP client setup - just a clear description of what you're testing. Under the hood, you get all the power of RSpec's matchers, Faker's data generation, and FactoryBot's test objects.

## Why SpecForge?

1. **Living Documentation**: Your tests should serve as clear, readable documentation of your API's behavior.
2. **Reduce Boilerplate**: Write tests without repetitive setup code and HTTP configuration.
3. **Quick Setup**: Start testing APIs in minutes instead of spending hours on test infrastructure.
4. **Gradual Adoption**: Use alongside your existing test suite, introducing it incrementally where it makes sense.
5. **Developer & QA Collaboration**: Create a testing format that everyone can understand and maintain, regardless of Ruby expertise.

## Key Features

- **YAML-Based Tests**: Write clear, declarative tests that read like documentation
- **RSpec Integration**: Leverage all the power of RSpec matchers and expectations
- **FactoryBot Integration**: Generate test data with FactoryBot integration
- **Faker Integration**: Create realistic test data with Faker
- **Variable System**: Define and reference variables for dynamic test data
- **Context Storage**: Store API responses and reference them in subsequent tests
- **Compound Matchers**: Combine multiple validations with `matcher.and` for precise expectations
- **Global Variables**: Define shared configuration at the file level
- **Callback System**: Hook into the test lifecycle using Ruby for setup, teardown, and much more!

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

Run your tests:

```bash
spec_forge run
```

## Documentation

For comprehensive documentation, visit the [SpecForge Wiki](https://github.com/itsthedevman/spec_forge/wiki) which includes:

- [Getting Started Guide](https://github.com/itsthedevman/spec_forge/wiki/Getting-Started)
- [Configuration Options](https://github.com/itsthedevman/spec_forge/wiki/Configuration)
- [Writing Tests](https://github.com/itsthedevman/spec_forge/wiki/Writing-Tests)
- [Dynamic Features](https://github.com/itsthedevman/spec_forge/wiki/Dynamic-Features)
- [Factory Support](https://github.com/itsthedevman/spec_forge/wiki/Factory-Support)
- [RSpec Matchers](https://github.com/itsthedevman/spec_forge/wiki/RSpec-Matchers)

Also see the [API Documentation](https://itsthedevman.com/docs/spec_forge).

## Future Development

For the latest development priorities and feature ideas, check out our [GitHub Projects board](https://github.com/itsthedevman/spec_forge/projects). Have a feature request? Open an issue on GitHub!

## Contributing

Contributions are welcome! See the [Contributing Guide](https://github.com/itsthedevman/spec_forge/wiki/Contributing) for details on how to get started.

## License

The gem is available as open source under the terms of the [MIT License](LICENSE.txt).

## Looking for a Software Engineer?

I'm currently looking for opportunities where I can tackle meaningful problems and help build reliable software while mentoring the next generation of developers. If you're looking for a senior engineer with full-stack Rails expertise and a passion for clean, maintainable code, let's talk!

[bryan@itsthedevman.com](mailto:bryan@itsthedevman.com)
