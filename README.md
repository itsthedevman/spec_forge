# SpecForge

Ever notice how much time you spend writing code for API tests? Skip the boilerplate and write your tests in YAML - simple, clean, and powerful.

```yaml
get_user:
  path: /users/1
  expect:
    status: 200
    json:
      name: kind_of.string
      email: /@/
```

That's it. No Ruby classes, no setup code, no HTTP client configuration. Just describe what you want to test, and SpecForge handles the rest. Need test data? We've got Faker built in. Want to reuse objects? Factories are ready to go. All the power of RSpec's matchers without writing a single line of Ruby.

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

The configuration file (`spec_forge/config.yml`) supports ERB and allows you to set global options for your test suite.

### Base URL

The base URL can be specified at three levels (in order of precedence):
1. Expectation level
2. Spec level
3. Config level (`config.yml`)

```yaml
# config.yml
base_url: https://api.example.com

# specs/users.yml
get_user:
  base_url: https://staging.example.com  # Overrides config.yml
  path: /users/1
  expectations:
  - name: "Production check"
    base_url: https://prod.example.com  # Overrides spec level
    expect:
      status: 200
```

### Authorization

SpecForge currently supports header-based authorization. Configure it in your `config.yml`:

```yaml
authorization:
  default:
    header: Authorization
    value: Bearer <%= ENV['API_TOKEN'] %>  # ERB is supported!
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

For POST/PUT/PATCH requests, you can include query parameters and body data:

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
          matchers.include:
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

Define factories in `spec_forge/factories/user.yml`:

```yaml
user:
  class: User  # Optional model class name
  attributes:
    name: faker.name.name
    email: faker.internet.email
    role: admin
```

Use factories in your tests:

```yaml
create_post:
  variables:
    author: factories.user
    reviewers:
    - factories.user
    - factories.user
  body:
    title: faker.lorem.sentence
    content: faker.lorem.paragraphs
    author_id: variables.author.id
    reviewer_ids:
    - variables.reviewers.0.id
    - variables.reviewers.1.id
  expectations:
  - expect:
      status: 201
      json:
        author:
          id: variables.author.id
          name: variables.author.name
        reviewers:
        - id: variables.reviewers.0.id
        - id: variables.reviewers.1.id
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
      matchers.include:
      - featured
      - published

    slug: /^[a-z0-9-]+$/    # Shorthand for matching regexes

    # Any RSpec matcher can be used
    config:
      matchers.have_key: api_version
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
