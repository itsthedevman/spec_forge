# SpecForge

**Please note: This gem is under active development and isn't quite ready for use**

I have 99% of the first release done, but I still have a lot of testing and polishing to ensure it works as expected.

---

Write API tests in YAML that read like documentation:

```yaml
user_profile:
  path: /users/1
  expect:
    status: 200
    json:
      name: kind_of.string
      email: /@/
```

That's a complete test. No Ruby code, no configuration files, no HTTP client setup - just a clear description of what you're testing. Under the hood, you get all the power of RSpec's matchers, Faker's data generation, and FactoryBot's test objects.

But that's just scratching the surface.

## Table of Contents

- [Features](#features)
- [Compatibility](#compatibility)
- [Installation](#installation)
- [Getting Started](#getting-started)
- [Writing Your First Test](#writing-your-first-test)
- [Configuration](#configuration)
  - [Base URL](#base-url)
  - [Authorization](#authorization)
- [The Spec Structure](#the-spec-structure)
  - [Basic Structure](#basic-structure)
  - [Testing Response Data](#testing-response-data)
  - [Multiple Expectations](#multiple-expectations)
  - [Request Data](#request-data)
- [Dynamic Features](#dynamic-features)
  - [Variables](#variables)
  - [Transformations](#transformations)
  - [Factory Integration](#factory-integration)
- [RSpec Matchers](#rspec-matchers)
  - ["be" namespace](#be-namespace)
  - ["kind_of" namespace](#kind_of-namespace)
  - ["matchers" namespace](#matchers-namespace)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)
- [Looking for a Software Engineer?](#looking-for-a-software-engineer)

## Features

- **Write Tests in YAML**: Create clear, maintainable API tests using a declarative YAML syntax
- **RSpec Integration**: Harness RSpec's powerful matcher system and reporting through an intuitive interface
- **Dynamic Test Data**: Generate realistic test data using Faker, transformations, and a flexible variable system
- **Factory Integration**: Seamless integration with FactoryBot for test data generation

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

This creates the `spec_forge` directory with the following structure:
```
spec_forge/
  factories/        # Your factory definitions
  specs/            # Your test specifications
  forge_helper.rb   # Global configuration
```

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
  - name: "Retrieves a user successfully"
    expect:
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

# Configuration

When you initialize SpecForge, it creates a `forge_helper.rb` file in your `spec_forge` directory. This serves as your central configuration file:

## Basic Configuration

```ruby
SpecForge.configure do |config|
  # Base URL for all requests
  config.base_url = "http://localhost:3000"

  # Default headers sent with every request
  config.headers = {
    "Authorization" => "Bearer #{ENV.fetch('API_TOKEN', '')}",
    "Accept" => "application/json"
  }

  # Optional: Default query parameters for all requests
  config.query = {
    api_key: ENV['API_KEY']
  }
end
```

## Framework Integration

SpecForge works seamlessly with Rails and RSpec. Just uncomment the relevant sections in your forge helper:

```ruby
# Rails Integration
require_relative "../config/environment"

# RSpec Integration (includes your existing configurations)
require_relative "../spec/spec_helper"

# Load custom files (models, libraries, etc)
Dir[File.join(__dir__, "..", "lib", "**", "*.rb")].sort.each { |f| require f }
```

## Factory Configuration

SpecForge automatically discovers your FactoryBot factories, but you can customize this behavior:

```ruby
SpecForge.configure do |config|
  # Disable auto-discovery if needed
  config.factories.auto_discover = false

  # Add custom factory paths (appends to default paths)
  config.factories.paths += ["lib/factories"]
end
```

## Debug Configuration

Need to debug a specific test? Add `debug: true` to any spec and configure how to handle breakpoints:

```ruby
SpecForge.configure do |config|
  # Custom debug handler (defaults to printing state overview)
  config.on_debug { binding.pry }
end
```

Available debug context includes: `expectation`, `variables`, `request`, `response`, `expected_status`, and `expected_json`.

## Test Framework Configuration

You can access RSpec's configuration through the `specs` attribute. This is particularly useful for database cleaners and test setup:

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

## Configuration Inheritance

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
  - name: "Production check"
    base_url: https://prod.example.com
    headers:
      X-Custom-Header: "expectation-specific"
    expect:
      status: 200
```

## The Spec Structure

### Basic Structure

Every spec needs a path, HTTP method, and at least one expectation to be useful:

```yaml
show_user:
  path: /users/1
  method: GET # Optional for GET requests, can be lowercase too if that's your style
  expectations:
  - name: "Retrieves a User"  # Recommended. May be required in future versions for OpenAPI generation
    expect:
      status: 200
```

### Testing Response Data

Let's verify the response JSON:

```yaml
show_user:
  path: /users/1
  method: GET
  expectations:
  - name: "Retrieves a User"
    expect:
      status: 200
      json:
        id: 1
        name: kind_of.string
        role: admin
```

### Multiple Expectations

Each expectation can override any spec-level setting. This is useful for testing different scenarios:

```yaml
show_user:
  path: /users/1
  method: GET
  expectations:
  - name: "Retrieves a User"
    expect:
      status: 200
      json:
        id: 1
        role: admin
  - name: "Invalid User ID"
    path: /users/999  # Overrides spec-level path
    expect:
      status: 404
```

### Request Data

Add query parameters and body data to any request:

```yaml
create_user:
  path: /users
  method: POST
  query:  # or 'params' if you prefer
    team_id: 123
  body:   # or 'data' if you prefer
    name: John Doe
    email: john@example.com
    role: admin
  expectations:
  - expect:
      status: 201
      json:
        id: kind_of.integer
        name: John Doe
```

### Path Parameters

Query parameters aren't just for filtering and search - they're also how you handle dynamic path parameters. Instead of hardcoding IDs in your paths, use placeholders:

```yaml
show_user:
  path: /users/{id}  # Use {id} or :id - both work!
  query:
    id: 1  # This replaces the placeholder
  expect:
    status: 200
    json:
      name: kind_of.string
      email: /@/
```

## Dynamic Features

SpecForge provides powerful features for generating and manipulating test data dynamically.

### Variables

Variables let you define and reuse values across your tests. They support complex chaining and can reference generated data:

```yaml
list_posts:
  path: /posts
  variables:
    author: factories.user
    category_name: faker.lorem.word
  query:
    author_id: variables.author.id
    category: variables.category_name
  expectations:
  - name: "Lists user's posts"
    expect:
      status: 200
      json:
        posts:
          matcher.include:
          - author:
              id: variables.author.id
              name: variables.author.name
            category: variables.category_name
```

Variables support deep traversal:
```yaml
variables:
  user: factories.user
  first_post: variables.user.posts.last
  author: variables.first_post.comments.2.author.name
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

### Factory Configuration

SpecForge provides flexible configuration options for working with FactoryBot factories. By default, it will automatically discover factories in standard paths (`spec/factories` and `test/factories`).

#### Automatic Factory Discovery

The `auto_discover` setting controls whether SpecForge searches for factories in the configured paths:

```ruby
SpecForge.configure do |config|
  # Disable automatic factory discovery if needed (default: true)
  config.factories.auto_discover = false
end
```

When `auto_discover` is enabled (the default), SpecForge will:
1. Search all configured factory paths
2. Load any Ruby factory definitions (`*.rb` files)
3. Load any YAML factory definitions (`*.yml` files)

Note: FactoryBot will raise an error if you attempt to define a factory name that already exists. Make sure your factory names are unique across both Ruby and YAML definitions.

#### Custom Factory Paths

You can add custom paths to the factory search list:

```ruby
SpecForge.configure do |config|
  # Add custom factory paths (appends to default paths)
  config.factories.paths += ["lib/factories"]
end
```

Note: Custom paths are only used when `auto_discover` is enabled. If you disable auto-discovery, you'll need to manually require your factory files:

```ruby
SpecForge.configure do |config|
  config.factories.auto_discover = false

  # Manually require factories when auto-discovery is disabled
  Dir[File.join("lib/factories", "**", "*.rb")].sort.each { |f| require f }
end
```

#### YAML Factory Definitions

Regardless of the `auto_discover` setting, SpecForge will always load YAML factory definitions from the `spec_forge/factories/` directory. These files use a simple declarative syntax:

```yaml
# spec_forge/factories/user.yml
user:
  class: User  # Optional model class name
  variables:   # You can use variables here too!
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

SpecForge provides access to RSpec's powerful matcher system through an intuitive dot notation syntax. The matcher system dynamically integrates with RSpec's matchers through three main namespaces:

#### "be" namespace
```yaml
expect:
  json:
    # Simple predicates
    active: be.true
    deleted: be.false
    description: be.nil
    tags: be.empty
    email: be.present

    # Comparisons (aliases available)
    price:
      be.greater_than: 18            # be.greater also works
    stock:
      be.less_than_or_equal: 100     # be.less_or_equal also works
    rating:
      be.between:
      - 1
      - 5

    # Dynamic predicate methods
    published: be.published          # Maps to be_published
    admin: be.admin                  # Maps to be_admin
```

#### "kind_of" namespace
```yaml
expect:
  json:
    id: kind_of.integer
    name: kind_of.string
    metadata: kind_of.hash
    scores: kind_of.array
```

#### "matchers" namespace
```yaml
expect:
  json:
    # Direct RSpec matcher usage
    tags:
      matcher.include:
      - featured
      - published

    slug: /^[a-z0-9-]+$/    # Shorthand for matching regexes

    # Any RSpec matcher can be used
    config:
      matcher.have_key: api_version
```

Note: Matchers that require Ruby blocks (like `change`) are not supported.

## Roadmap

- [ ] Negated matchers
- [ ] OpenAPI generation from your tests
- [ ] Support for XML/HTML response handling
- [ ] Support for running individual specs

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
