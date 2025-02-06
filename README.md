# SpecForge

SpecForge is a Ruby gem that enables you to write expressive API tests using YAML. By eliminating boilerplate code and providing a clean, declarative syntax, SpecForge allows you to focus on defining your test scenarios rather than wrestling with test implementation.

## Features

- **Write Tests in YAML**: Create clear, maintainable API tests using a declarative YAML syntax
- **RSpec Integration**: Uses RSpec under the hood for test execution and reporting
- **Intuitive Matcher Access**: Clean syntax for RSpec matchers and expectations
- **Dynamic Test Data**: Generate realistic test data using Faker, transformations, and variables
- **Factory Integration**: Seamless integration with FactoryBot for fixture generation
- **OpenAPI Generation** (Coming Soon): Automatically generate OpenAPI documentation from your test specifications

## Requirements

- Ruby 3.0+

## Installation

Add this line to your application's Gemfile:

```ruby
gem spec_forge
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

This creates the `spec_forge` directory with the following structure:
```
spec_forge/
  config.yml
  factories/
  specs/
```

### Configuration

Create a minimal configuration in `spec_forge/config.yml`:

```yaml
base_url: http://localhost:3000
authorization:
  default:
    header: Authorization
    value: Bearer <%= ENV.fetch('API_TOKEN') %>
```

### Basic Test

Create a test specification in `spec_forge/specs/users_api.yml`:

```yaml
get_user:
  path: /api/users/1
  method: get
  variables:
    base_name: faker.name.name
  query:
    include_details: true
expectations:
- query:
    include_details: false
  expect:
    status: 200
    json:
      id: kind_of.integer
      name: variables.base_name
- variables:
    admin_name: faker.name.name
  body:
    name: variables.admin_name
  expect:
    status: 200
    json:
      id: kind_of.integer
      name: variables.admin_name
      details: kind_of.hash
```

Run your tests:

```bash
spec_forge run
```

## Advanced Usage

### Factory Integration

Define factories in `spec_forge/factories/user.yml`:

```yaml
user:
  class: User
  attributes:
    name: faker.string.random
    email: faker.internet.email
```

Use factories in tests:

```yaml
create_post:
  path: /api/posts
  method: post
  variables:
    author: factory.user
    category: factory.category
  body:
    title: faker.lorem.sentence
    content: faker.lorem.paragraphs
    author_id: variables.author.id
    category_id: variables.category.id
expectations:
- expect:
    status: 201
    json:
      id: kind_of.integer
      title: matcher.be_present
      author:
        id: variables.author.id
        name: variables.author.name
```

### URL Configuration

The base URL can be specified at three levels (in order of precedence):
1. Expectation level
2. Spec level
3. Config level (`config.yml`)

### Dynamic Variables and Transforms

Generate and transform test data:

```yaml
update_user:
  path: /api/users/1
  method: patch
  variables:
    first_name: faker.name.first_name
    last_name: faker.name.last_name
    full_name:
      transform.join:
        - variables.first_name
        - " "
        - variables.last_name
    age:
      faker.number.between:
        from: 18
        to: 65
  body:
    name: variables.full_name
    age: variables.age
expectations:
- expect:
    status: 200
    json:
      name: variables.full_name
      age: variables.age
```

## Matcher Reference

### "be" namespace

| Macro | RSpec |
| -------------------------- | ------------ |
| be.nil | be(nil) |
| be.true | be(true) |
| be.false | be(false) |
| be.present | be_present |
| be.empty | be_empty |
| be.truthy | be_truthy |
| be.falsey | be_falsey |
| be.greater_than | be > |
| be.less_than | be < |
| be.greater_than_or_equal | be >= |
| be.less_than_or_equal | be <= |
| be.between | be_between |
| be.within | be_within |

### "kind_of" namespace

| Macro | RSpec |
| ----------------- | --------------------- |
| kind_of.integer | be_kind_of(Integer) |
| kind_of.string | be_kind_of(String) |
| kind_of.array | be_kind_of(Array) |
| kind_of.hash | be_kind_of(Hash) |
| kind_of.float | be_kind_of(Float) |

### "matcher" namespace

| Macro | RSpec |
| ------------------------- | ----------------- |
| matcher.contain_exactly | contain_exactly |
| matcher.match | match |
| matcher.match_array | match_array |
| matcher.have_key | have_key |
| matcher.start_with | start_with |
| matcher.end_with | end_with |
| matcher.include | include |
| matcher.include_hash | include_hash |
| matcher.have_attributes | have_attributes |

## Limitations

- RSpec matchers requiring Ruby blocks (like `change`) are not supported

## Roadmap

- OpenAPI document generation
- Support for XML/HTML response handling
- Potential support for parallel test execution

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b feature/my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin feature/my-new-feature`)
5. Create new Pull Request

Please note that this project is released with a [Contributor Code of Conduct](CODE_OF_CONDUCT.md). By participating in this project you agree to abide by its terms.

## License

The gem is available as open source under the terms of the [MIT License](LICENSE.txt).

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a list of changes.

## Credits

- Author: Bryan "itsthedevman"
