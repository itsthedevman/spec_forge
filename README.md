
# SpecForge

SpecForge is a Ruby gem that enables you to write expressive API tests using YAML. By eliminating boilerplate code and providing a clean, declarative syntax, SpecForge allows you to focus on defining your test scenarios rather than wrestling with test implementation.

## Features

- **Write Tests in YAML**: Create clear, maintainable API tests using a declarative YAML syntax
- **RSpec Integration**: Uses RSpec under the hood for test execution and reporting
- **Intuitive Matcher Access**: Clean syntax for RSpec matchers and expectations
- **Dynamic Test Data**: Generate realistic test data using Faker, transformations, and variables
- **Factory Integration**: Seamless integration with FactoryBot for fixture generation
- **OpenAPI Generation** (Coming Soon): Automatically generate OpenAPI documentation from your test specifications

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
  config.yml
  factories/
  specs/
```

## Creating a spec

Specs can be created using:
```bash
bundle exec spec_forge new spec <file_name>
```
_Note: You can also use `generate` or `g` instead of `new` if you prefer_

This will create the file `spec_forge/specs/<name>.yml` and populate it with example specs for CRUD routes.

## Running the specs

Once you have a spec forged, you can all tests using:
```bash
bundle exec spec_forge run
```

## Config

Location: `spec_forge/config.yml`

This file supports ERB.

### `base_url`

The base URL can be specified at three levels (in order of precedence):
1. Expectation level
2. Spec level
3. Config level (`config.yml`)

### `authorization`

SpecForge currently only supports header based authorization.

```yaml
authorization:
  default:
    header: Authorization
    value: Bearer MY_TOKEN
```

## The Spec Structure

Each spec is defined by a unique name within that file.

```yaml
show_user:
  path: /user/1
  method: GET
  expectations: []
```

This is an example of a minimal spec with no tests. We have a path and the HTTP method used.

Let's add an expectation

```yaml
show_user:
  path: /user/1
  method: GET
  expectations:
  - name: "Retrieves a User"
    expect:
      status: 200
```

An expectation can override anything defined on the spec.

```yaml
show_user:
  path: /users/1
  method: GET
  expectations:
  - name: "Retrieves a User"
    expect:
      status: 200
  - name: "Invalid ID"
    path: /users/0
    expect:
      status: 404
```

This is fine but this doesn't test much. Let's test the response's JSON:

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
  - name: "Invalid ID"
    path: /users/0
    expect:
      status: 404
```

As of right now, SpecForge only supports JSON response checking. Check out the [[#Roadmap]]

## RSpec Matchers

Checking for literal values is ok, but what if you don't know the exact data? Enter RSpec's matcher system.
_For brevity, we're going to focus just on a single expectation in these examples. Assume this is being used within the spec context above_

```yaml
name: "Retrieves a User"
expect:
  status: 200
  json:
    id: 1
    role: admin
    name: kind_of.string
    last_logged_in_at: be.blank
```

SpecForge utilizes a powerful dot notation system in order to do cool things. It is able to use most of RSpec's matchers, including dynamic ones. In fact, both `id` and `role` values above are converted to `eq(1)` and `eq("admin")` respectfully.

I've included a non-exhaustive list of matchers below to give you the idea.

## Expanded notation

SpecForge supports positional and keyword argument forwarding

```yaml
name: "Retrieves a User"
expect:
  status: 200
  json:
    id: 1
    role:
      matchers.include:
      - admin
      - user
      - guest
    name: kind_of.string
```

The above `matchers.include` reference will create a `include("admin", "user", "guest")` matcher. You can use a hash for keyword arguments
```yaml
name: "Retrieves a User"
expect:
  status: 200
  json:
    id: 1
    name: kind_of.string
    keys:
      matchers.include:
        room: kind_of.integer
        locker: kind_of.integer
```
## Limitations

- RSpec matchers requiring Ruby blocks (like `change`) are not supported

## Roadmap

- [ ] Negated matchers
- [ ] Support for running a single spec
- [ ] OpenAPI document generation
- [ ] Support for XML/HTML response handling

## Potential features

- [ ] Parallel test execution

## Tested on

MRI Ruby 3.0+, NixOS (see `flake.nix`)

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

## Looking for a Software Engineer?

I'm looking for work! Please send enquiries to bryan@itsthedevman.com

## Credits

- Author: Bryan "itsthedevman"

---

Editor's note: Everything below is important but needs rewritten into the above

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
