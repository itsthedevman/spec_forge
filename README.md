# SpecForge

Write API tests in YAML that read like documentation:

```yaml
user_profile:
  path: /users/1
  expectations:
  - expect:
      status: 200
    json:
      name: kind_of.string
      email: /@/
```

That's a complete test. No Ruby code, no configuration files, no HTTP client setup - just a clear description of what you're testing. Under the hood, you get all the power of RSpec's matchers, Faker's data generation, and FactoryBot's test objects.

## Why SpecForge?

SpecForge shines when you need:

1. **Accessible API Testing**: Non-developers can write and maintain tests without Ruby knowledge. The YAML syntax reads like documentation.
2. **Living Documentation**: Tests serve as clear, maintainable documentation of your API's expected behavior.
3. **Power Without Complexity**: Get the benefits of Ruby-based tests (dynamic data, factories, matchers) without writing Ruby code.
4. **Quick Setup**: Start testing APIs without configuring HTTP clients or writing boilerplate code.
5. **Gradual Adoption**: Use alongside your existing test suite. Keep complex tests in RSpec while making simple API tests more accessible.

## When Not to Use SpecForge

Consider alternatives when you need:

1. **Complex Ruby Logic**: If your tests require custom Ruby code for data transformations or validations.
2. **Complex Test Setup**: When you need intricate database states or specific service mocks.
3. **Custom Response Validation**: For validation logic beyond what matchers provide.
4. **Complex Non-JSON Testing**: While SpecForge handles basic XML/HTML responses (coming soon), complex validation might need specialized tools.

## Roadmap

Current development priorities:
- [ ] Support for running individual specs
- [ ] Array support for `json` expectations
- [ ] Negated matchers: `matcher.not`
- [ ] `create_list/build_list` factory strategies
- [ ] `transform.map` support
- [ ] Improved error handling
- [ ] XML/HTML response handling
- [ ] OpenAPI generation from tests

Have a feature request? Open an issue on GitHub!

## Table of Contents

- [Features](#features)
- [Compatibility](#compatibility)
- [Installation](#installation)
- [Getting Started](#getting-started)
- [Writing Your First Test](#writing-your-first-test)
- [Configuration](#configuration)
  - [Basic Configuration](#basic-configuration)
  - [Framework Integration](#framework-integration)
  - [Factory Configuration](#factory-configuration)
  - [Debug Configuration](#debug-configuration)
  - [Test Framework Configuration](#test-framework-configuration)
  - [Configuration Inheritance](#configuration-inheritance)
- [Writing Tests](#writing-tests)
  - [Basic Structure](#basic-structure)
  - [Testing Response Data](#testing-response-data)
  - [Multiple Expectations](#multiple-expectations)
  - [Request Data](#request-data)
  - [Path Parameters](#path-parameters)
- [Dynamic Features](#dynamic-features)
  - [Variables](#variables)
  - [Transformations](#transformations)
  - [Chaining Support](#chaining-support)
- [Factory Support](#factory-support)
  - [Automatic Discovery](#automatic-discovery)
  - [Custom Factory Paths](#custom-factory-paths)
  - [Build Strategies](#build-strategies)
  - [YAML Factory Definitions](#yaml-factory-definitions)
- [RSpec Matchers](#rspec-matchers)
  - ["be" namespace](#be-namespace)
  - ["kind_of" namespace](#kind_of-namespace)
  - ["matchers" namespace](#matchers-namespace)
- [How Tests Work](#how-tests-work)
- [Contributing](#contributing)
- [License](#license)
- [Looking for a Software Engineer?](#looking-for-a-software-engineer)

## Compatibility

Currently tested on:
- MRI Ruby 3.0+
- NixOS (see `flake.nix` for details)

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

Or with bundle:
```bash
bundle exec spec_forge init
```

This creates the `spec_forge` directory containing factory definitions, test specifications, and global configuration.

## Writing Your First Test

Let's write a simple test to verify a user endpoint. Create a new spec file:

```bash
spec_forge new spec users
```

This creates `spec_forge/specs/users.yml`. Here's a basic example:

```yaml
get_user:
  path: /users/1
  method: GET
  expectations:
  - expect:
      status: 200
      json:
        id: 1
        name: kind_of.string
        email: /@/
```

Run your tests with:

```bash
spec_forge run
```

## Configuration

### Basic Configuration

When you initialize SpecForge, it creates a `forge_helper.rb` file in your `spec_forge` directory. This serves as your central configuration file:

```ruby
SpecForge.configure do |config|
  # Base URL for all requests
  config.base_url = "http://localhost:3000"

  # Default headers sent with every request
  config.headers = {
    "Authorization" => "Bearer #{ENV.fetch("API_TOKEN", "")}",
    "Accept" => "application/json"
  }

  # Optional: Default query parameters for all requests
  config.query = {
    api_key: ENV["API_KEY"]
  }
end
```

### Framework Integration

SpecForge works seamlessly with Rails and RSpec:

```ruby
# Rails Integration
require_relative "../config/environment"

# RSpec Integration (includes your existing configurations)
require_relative "../spec/spec_helper"

# Load custom files (models, libraries, etc)
Dir[File.join(__dir__, "..", "lib", "**", "*.rb")].sort.each { |f| require f }
```

### Factory Configuration

SpecForge provides flexible configuration options for working with FactoryBot factories:

```ruby
SpecForge.configure do |config|
  # Disable auto-discovery if needed (default: true)
  config.factories.auto_discover = false

  # Add custom factory paths (appends to default paths)
  config.factories.paths += ["lib/factories"]
end
```

### Debug Configuration

Enable debugging by adding `debug: true` (aliases: `breakpoint`, `pry`) at either the spec or expectation level:

```ruby
SpecForge.configure do |config|
  # Custom debug handler (defaults to printing state overview)
  config.on_debug { binding.pry }  # Requires 'pry' gem
end
```

```yaml
get_users:
  debug: true  # Debug all expectations in this spec
  path: /users
  expectations:
  - expect:
      status: 200
  - debug: true  # Debug just this expectation
    expect:
      status: 404
      json:
        error: kind_of.string
```

When debugging, you have access to:
- `expectation` - Current expectation being validated
- `variables` - Resolved variables for the current expectation
- `request` - Request details (url, method, headers, etc.)
- `response` - Full response including headers, status, and parsed body
- `expected_status` - Expected HTTP status code
- `expected_json` - Expected JSON structure with matchers

Or call `self` from an interactive session to see everything as a hash

### Test Framework Configuration

Access RSpec's configuration through the `specs` attribute:

```ruby
SpecForge.configure do |config|
  # Setup before all tests
  config.specs.before(:suite) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean_with(:truncation)
  end

  # Wrap each test
  config.specs.around do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
```

### Configuration Inheritance

All configuration options can be overridden at three levels (in order of precedence):

1. Individual expectation
2. Spec level
3. Global configuration (forge_helper.rb)

For example:

```yaml
# Override at spec level
get_user:
  base_url: https://staging.example.com
  headers:
    X-Custom-Header: "overridden"

  expectations:
  # Override for a specific expectation
  - base_url: https://prod.example.com
    headers:
      X-Custom-Header: "expectation-specific"
    expect:
      status: 200
```

## Writing Tests

### Basic Structure

Every spec needs a path, HTTP method, and at least one expectation:

```yaml
show_user:
  path: /users/1
  method: GET  # Optional for GET requests
  expectations:
  - expect:
      status: 200
```

### Testing Response Data

Verify the response JSON:

```yaml
show_user:
  path: /users/1
  expectations:
  - expect:
      status: 200
      json:
        id: 1
        name: kind_of.string
        role: admin
```

### Multiple Expectations

Each expectation can override any spec-level setting:

```yaml
show_user:
  path: /users/1
  expectations:
  - expect:
      status: 200
      json:
        id: 1
        role: admin
  - path: /users/999  # Overrides spec-level path
    expect:
      status: 404
```

### Request Data

Add query parameters and body data:

```yaml
create_user:
  path: /users
  method: POST
  query:  # or "params" if you prefer
    team_id: 123
  body:   # or "data" if you prefer
    name: John Doe
    email: john@example.com
  expectations:
  - expect:
      status: 201
```

### Path Parameters

Use placeholders for dynamic path parameters:

```yaml
show_user:
  path: /users/{id}  # Use {id} or :id
  query:
    id: 1  # Replaces the placeholder
  expectations:
  - expect:
      status: 200
```

## Dynamic Features

### Variables

Variables let you define and reuse values:

```yaml
list_posts:
  variables:
    author: factories.user
    category_name: faker.lorem.word
  query:
    author_id: variables.author.id
    category: variables.category_name
  expectations:
  - expect:
      status: 200
    json:
      posts:
        matcher.include:
        - author:
            id: variables.author.id
            name: variables.author.name
          category: variables.category_name
```

### Transformations

Transform data using built-in helpers:

```yaml
create_user:
  variables:
    first_name: faker.name.first_name
    last_name: faker.name.last_name
    full_name:
      transform.join:
      - variables.first_name
      - " "
      - variables.last_name
  body:
    name: variables.full_name
    email: faker.internet.email
```

### Chaining

Access nested attributes and methods through chaining:

```yaml
list_posts:
  variables:
    # Factory chaining examples
    owner: factories.user              # Creates a user
    name: factories.user.name          # Gets just the name
    company: variables.owner.company   # Access factory attributes

    # Variable chaining for relationships
    first_post: variables.user.posts.first

    # You can use array indices directly
    comment_author: variables.first_post.comments.2.author.name

    # Faker method chaining
    lowercase_email: faker.internet.email.downcase
    title_name: faker.name.first_name.titleize
```

### Factory Build Strategies

Control how factories create objects and customize their attributes:

```yaml
create_user:
  variables:
    # Default strategy (create)
    regular_user: factories.user

    # Custom build strategy and attributes
    custom_user:
      factory.user:
        strategy: build    # 'create' (default) or 'build'
        attributes:
          name: "Custom Name"
          email: faker.internet.email
```

## Factory Support

### Automatic Discovery

SpecForge automatically discovers factories in standard paths:

```ruby
SpecForge.configure do |config|
  # Disable automatic factory discovery if needed (default: true)
  config.factories.auto_discover = false
end
```

### Custom Factory Paths

Add custom paths to the factory search list:

```ruby
SpecForge.configure do |config|
  # Add custom factory paths (appends to default paths)
  # Ignored if `auto_discovery` is false
  config.factories.paths += ["lib/factories"]
end
```

### Factory Build Strategies

Control how factories create objects and customize their attributes:

```yaml
create_user:
  variables:
    # Default strategy (create)
    regular_user: factories.user

    # Custom build strategy and attributes
    custom_user:
      factory.user:
        strategy: build    # 'create' (default) or 'build'
        attributes:
          name: "Custom Name"
          email: faker.internet.email
```

### YAML Factory Definitions

Define factories in YAML with a simple declarative syntax:

```yaml
# spec_forge/factories/user.yml
user:
  class: User  # Optional model class name
  variables:
    department: faker.company.department
    team_size:
      faker.number.between:
        from: 5
        to: 20
  attributes:
    name: faker.name.name
    email: faker.internet.email
    role: admin
    department: variables.department
    team_count: variables.team_size
```

## RSpec Matchers

### "be" namespace

```yaml
expect:
  json:
    # Simple predicates
    active: be.true
    deleted: be.false
    description: be.nil
    tags: be.empty
    email: be.present

    # Comparisons
    price:
      be.greater_than: 18
    stock:
      be.less_than_or_equal: 100
    rating:
      be.between:
      - 1
      - 5

    # Dynamic predicate methods
    published: be.published
    admin: be.admin
```

### "kind_of" namespace

```yaml
expect:
  json:
    id: kind_of.integer
    name: kind_of.string
    metadata: kind_of.hash
    scores: kind_of.array
```

### "matchers" namespace

```yaml
expect:
  json:
    tags:
      matcher.include:
      - featured
      - published

    slug: /^[a-z0-9-]+$/    # Shorthand for matching regexes

    config:
      matcher.have_key: api_version
```

## How Tests Work

When you write a YAML spec, SpecForge converts it into an RSpec test structure. For example, this YAML:

```yaml
create_user:
  path: /users
  method: POST
  variables:
    full_name: faker.name.name
  body:
    name: variables.full_name
  expectations:
  - expect:
      status: 201
      json:
        name: variables.full_name
```

Becomes this RSpec test:

```ruby
RSpec.describe "create_user" do
  describe "POST /users" do
    let(:full_name) { Faker::Name.name }

    let!(:expected_status) { 201 }
    let!(:expected_json) do
      {
        name: eq(full_name)
      }
    end

    subject(:response) do
      post("/users", body: { name: full_name })
    end

    it do
      expect(response.status).to eq(expected_status)
      expect(response.body).to include(expected_json)
    end
  end
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b feature/my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin feature/my-new-feature`)
5. Create new Pull Request

Please note that this project is released with a [Contributor Code of Conduct](CODE_OF_CONDUCT.md). By participating in this project you agree to abide by its terms.

## License

The gem is available as open source under the terms of the [MIT License](LICENSE.txt).

## Looking for a Software Engineer?

I'm looking for work! Please send serious enquiries to bryan@itsthedevman.com
