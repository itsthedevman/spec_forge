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
  config.yml      # Global configuration
  factories/      # Your factory definitions
  specs/          # Your test specifications
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

## Configuration

When you initialize SpecForge, it'll create a `forge_helper.rb` file in your `spec_forge` directory. This is where all your configuration lives:

```ruby
SpecForge.configure do |config|
  config.base_url = "http://localhost:3000"

  config.headers = {
    "Authorization" => "Bearer #{ENV['API_TOKEN']}"
  }
end
```

That's all you need to get started. But there's more you can configure:

### Base URL

All your test paths get appended to this URL. You can override it at three levels (in order of precedence):

1. In a specific expectation
2. At the spec level
3. In your forge helper

```yaml
# Override at spec level
get_user:
  base_url: https://staging.example.com
  path: /users/1

  expectations:
  # Override for a specific test
  - name: "Production check"
    base_url: https://prod.example.com
    expect:
      status: 200
```

### Request Headers

You can configure the default headers from here as well. Just like with the `base_url`, these can be added to or overwritten on the spec/expectation level.

```ruby
SpecForge.configure do |config|
  config.headers = {
    "Authorization" => "Bearer #{ENV['API_TOKEN']}",
    "Accept" => "application/json",
    "X-API-Version" => "2"
  }
end
```

### Factory Configuration

Using FactoryBot already? SpecForge automatically discovers your factories, but you can customize this:

```ruby
SpecForge.configure do |config|
  # Disable auto-discovery if you want
  config.factories.auto_discover = false

  # Add custom factory paths
  config.factories.paths += ["custom/factories/path"]
end
```

### Using with Rails

Just uncomment the Rails section in your forge helper:

```ruby
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
```

Want to use your existing RSpec configuration? Uncomment the RSpec line:

```ruby
require_relative "../spec/spec_helper"
```

### RSpec Configuration

You can also access RSpec's configuration directly through the `specs` attribute:

```ruby
SpecForge.configure do |config|
  config.specs.before(:suite) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean_with(:truncation)
  end

  config.specs.around do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
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

### Factory Integration

SpecForge provides a YAML interface to FactoryBot, making it easy to define and use factories in your tests:

1. **Existing FactoryBot Factories**: Out of the box, SpecForge automatically discovers your existing Ruby-defined factories from:
   - Standard paths (`spec/factories` and `test/factories`)
   - Any custom paths you configure in your `forge_helper.rb`:
     ```ruby
     SpecForge.configure do |config|
       # Add custom factory paths
       config.factories.paths += ["custom/factories/path"]

       # Disable automatic factory discovery if needed (default: true)
       config.factories.auto_discover = false
     end
     ```

2. **YAML Factory Definitions**: Define factories using YAML in `spec_forge/factories/`:
   ```yaml
   # spec_forge/factories/user.yml
   user:
     class: User  # Optional model class name
     attributes:
       name: faker.name.name
       email: faker.internet.email
       role: admin
   ```
   SpecForge registers these YAML definitions with FactoryBot, making them work exactly like Ruby-defined factories.

Use factories in your tests:
```yaml
create_post:
  variables:
    author: factories.user  # Works with both YAML and Ruby-defined factories
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
