
# SpecForge 1.0 Technical Specification

## Table of Contents

- [Philosophy](#philosophy)
- [Load-time vs Run-time](#load-time-vs-run-time)
- [File Structure](#file-structure)
- [Reserved Namespaces](#reserved-namespaces)
- [Variables](#variables)
- [String Interpolation](#string-interpolation)
- [Step Attributes](#step-attributes)
- [Core Attributes](#core-attributes)
- [Request Configuration](#request-configuration)
- [Expectations](#expectations)
- [Store](#store)
- [Callbacks](#callbacks)
- [Grouping Steps](#grouping-steps)
- [Including Files](#including-files)
- [Tags and Filtering](#tags-and-filtering)
- [Special Features](#special-features)
- [Directory Structure](#directory-structure)
- [Test Output and Verbosity](#test-output-and-verbosity)
- [Error Messages](#error-messages)
- [Complete Examples](#complete-examples)

---

## Philosophy

SpecForge 1.0 adopts a **step-based workflow architecture** where API tests are written as sequential actions rather than resource-centric test suites. This aligns with how developers naturally think about API testing: "First I do X, then Y happens, then I verify Z."

**Core Principles:**

- **Sequential execution** - Steps run top-to-bottom, values available after definition
- **Explicit evaluation** - `{{ }}` signals "process this expression"
- **Context-driven behavior** - Keywords adapt based on surrounding context
- **YAML-first simplicity** - Solve problems without requiring Ruby code when possible

---

## Load-time vs Run-time

SpecForge processes blueprints in two distinct phases that keep complexity manageable:

**Load-time (YAML → Blueprint)**

- Resolves all `include` directives by injecting referenced files
- Flattens nested `steps` hierarchies into sequential list
- Stamps each step with inherited configuration (request config, tags)
- Validates structure and applies normalization
- **Output:** Flat array of self-contained Step objects

**Run-time (Blueprint → Execution)**

- Receives flat list of steps, no hierarchy
- Executes steps sequentially, one after another
- Each step already has everything it needs baked in
- No parent lookups, no tree traversal, just iteration

**Why this matters:** Complexity is contained in the loader. The runner is brain-dead simple - just loop through steps and execute them. Includes and nesting are purely authoring conveniences that vanish before execution starts.

---

## File Structure

Each YAML file in `blueprints/` represents a complete workflow consisting of sequential steps:

```yaml
# users_workflow.yml
- hooks:
    before_file: prepare_database
    after_file: cleanup_database

- store:
    admin_email: "admin@test.com"

- name: "Login as admin"
  request:
    path: /auth/login
    method: POST
    json:
      email: "{{ admin_email }}"
      password: "admin123"
  store:
    auth_token: "{{ response.body.token }}"

- name: "Create user"
  request:
    path: /users
    method: POST
    headers:
      Authorization: "Bearer {{ auth_token }}"
    json:
      name: "Test User"
  expect:
  - status: 201
```

**Key points:**

- Array of step hashes at the root
- Steps execute sequentially (top to bottom)
- Later steps can reference values from earlier steps
- No implicit ordering or grouping

---

## Reserved Namespaces

The following prefixes trigger special behavior. How you use them depends on **position**:

|Namespace|Purpose|Value Position Example|Key Position Example|
|---|---|---|---|
|`faker.`|Generate fake data|`"{{ faker.name.first_name }}"`|`faker.number.between:`|
|`factories.`|Use FactoryBot|`"{{ factories.user.id }}"`|`factories.user:`|
|`generate.`|Generate arbitrary data|N/A|`generate.array:`|
|`env.`|Environment variables|`"{{ env.API_TOKEN }}"`|N/A|
|`kind_of.`|Type matchers|`"{{ kind_of.string }}"`|N/A|
|`matcher.`|RSpec matchers|`"{{ matcher.eq }}"`|`matcher.include:`|
|`be.`|Predicate matchers|`"{{ be.true }}"`|`be.greater_than:`|
|`transform.`|Data transformations|N/A|`transform.join:`|

**Position determines syntax** - see [String Interpolation](#string-interpolation) for details.

---

## Variables

SpecForge has two types of variables: **global** and **local**. Both are referenced the same way in templates (`{{ variable_name }}`), but they're defined differently and have different scopes.

### Global Variables

Global variables are defined in `forge_helper.rb` and are available to all blueprints:

```ruby
SpecForge.configure do |config|
  config.global_variables = {
    api_version: "v1",
    base_url: "https://api.example.com",
    admin_credentials: {
      email: "admin@test.com",
      password: "admin123"
    }
  }
end
```

**Use global variables for:**

- Configuration that applies across all tests
- Environment-specific settings (base URLs, API versions)
- Shared credentials or test data
- Constants that never change during test execution

### Local Variables

Local variables are defined within blueprints using the `store:` attribute:

```yaml
- store:
    user_email: "test@test.com"
    user_password: "testpass123"
    
- name: "Register"
  request:
    json:
      email: "{{ user_email }}"
      password: "{{ user_password }}"
```

**Use local variables for:**

- Test-specific data that changes between steps
- Values extracted from responses
- Temporary state that only matters within one blueprint

### Variable Lookup and Shadowing

When you reference `{{ variable_name }}`, SpecForge checks local variables first, then falls back to globals:

```yaml
# In forge_helper.rb
config.global_variables = {
  api_token: "global_secret"
}

# In blueprint
- name: "Use global token"
  request:
    headers:
      Authorization: "Bearer {{ api_token }}"  # Uses "global_secret"

- name: "Override with local"
  store:
    api_token: "local_override"
    
- name: "Use local token"
  request:
    headers:
      Authorization: "Bearer {{ api_token }}"  # Uses "local_override"
```

**Shadowing behavior:**

- Local variables can shadow (replace) global variables
- Later `store:` steps can shadow earlier ones
- Shadowing is scoped to the current blueprint - other blueprints still see the original values
- This is intentional and useful for test isolation

---

## String Interpolation

### The `{{ }}` Syntax

**Position-based rule:** Where you use namespaced attributes determines if you need `{{ }}`

```yaml
# VALUE POSITION - needs {{ }} (you're evaluating an expression)
email: "{{ faker.internet.email }}"
age: "{{ kind_of.integer }}"
token: "{{ response.body.auth_token }}"
path: "/users/{{ user_id }}"

# KEY POSITION - no {{ }} (you're declaring a constructor)
matcher.include: [1, 2, 3]
be.greater_than: 18
faker.number.between:
  from: 0
  to: 100
```

**Why this matters:**

Templates in value position evaluate to produce a value. You're saying "process this expression and give me the result."

Keys with namespaces declare constructors that take arguments. You're saying "build this thing using these parameters."

### Literal vs Evaluated

```yaml
# Literal values (no evaluation)
title: "My Title"
status: 200
active: true

# Evaluated expressions (needs {{ }})
email: "{{ faker.internet.email }}"
count: "{{ kind_of.integer }}"

# String interpolation
path: "/users/{{ user_id }}/posts"
message: "Hello {{ user_name }}"

# Attribute extraction from response
store:
  token: "{{ response.body.auth_token }}"
  user_id: "{{ response.body.user.id }}"
```

### Special Cases

**Type definitions in `structure:` blocks** - implicitly evaluated (no brackets needed):

```yaml
expect:
- json:
    structure:
      id: integer
      name: string
      email: string
      metadata: ?hash
      tags: array
```

**Matchers with arguments** - use key position syntax:

```yaml
expect:
- json:
    content:
      # Value position - evaluates to matcher
      id: "{{ kind_of.integer }}"
      
      # Key position - constructs matcher with args
      tags:
        matcher.include: ["admin", "user"]
      
      count:
        be.greater_than: 5
```

---

## Step Attributes

Every step is a hash that can contain any of these attributes:

```
Step
├── name (String, optional)
├── line_number (Integer, system-managed)
├── debug (Boolean, optional, default: false)
├── tags (Array<String>, optional, inheritable)
├── documentation (Hash, optional)
│   ├── summary (String)
│   ├── description (String)
│   └── tags (Array<String>)
├── request (Hash, optional, triggers HTTP behavior)
│   ├── base_url (String, inheritable)
│   ├── url (String, required if request present)
│   ├── method (String, optional, default: "GET")
│   ├── headers (Hash, inheritable, mergeable)
│   ├── query (Hash, inheritable, mergeable)
│   ├── raw (String, body format)
│   ├── json (Hash, body format)
│   └── xml (Hash, body format - future)
├── expect (Array<Expectation>, optional)
│   └── Expectation
│       ├── name (String, optional)
│       ├── status (Integer or Matcher, optional)
│       ├── headers (Hash, optional)
│       ├── raw (String or Matcher, optional)
│       ├── json (Hash, optional)
│       │   ├── size (Integer or Matcher, optional)
│       │   ├── pattern (Array or Hash, optional)
│       │   ├── structure (Array or Hash, optional)
│       │   └── content (Array or Hash, optional)
│       └── xml (Hash, optional - future)
│           ├── structure (Array or Hash)
│           └── content (Array or Hash)
├── store (Hash, optional, context-driven)
│   └── key: value (values support {{ }} interpolation)
├── call (String or Hash, optional, immediate callback)
├── steps (Array<Step>, optional, nested hierarchy)
└── include (Array<String>, optional, file injection)
```

### Load-time vs Run-time Attributes

**Resolved at load-time (gone by runtime):**

- `include` - File injection directive
- `steps` - Hierarchy flattened to sequential steps

**Modified at load-time:**

- `tags` - Inherited from parents, applied to step
- `request` - Merged with parent config, stamped on step

**Used at run-time:**

- `name`, `debug`, `documentation` - Step metadata
- `request`, `expect`, `store` - Execution behavior
- `call` - Lifecycle management

---

## Core Attributes

### `name` (String)

Human-readable identifier shown in test output.

```yaml
- name: "Create new user account"
```

### `debug` (Boolean)

Triggers breakpoint/debugger for this step only. Does **not** inherit to child steps.

```yaml
- name: "Login"
  debug: true
  steps:
  - name: "Get token"  # Does NOT trigger debug
```

Debugger behavior configured in `forge_helper.rb`:

```ruby
SpecForge.configure do |config|
  config.on_debug { binding.pry }
end
```

### `documentation` (Hash)

Metadata for OpenAPI generation.

```yaml
- documentation:
    summary: "Creates a new user"
    description: "Registers a user account..."
    tags: ["users", "authentication"]
```

---

## Request Configuration

### `request` (Hash)

Defines HTTP request to send. **Presence of this attribute changes step behavior** - step becomes "send request, optionally store response."

```yaml
request:
  base_url: "https://api.example.com"  # Optional
  url: "/users"                         # Required
  method: POST                          # Optional (default: GET)
  headers: {}                           # Optional
  query: {}                             # Optional
  
  # Body formats (pick one)
  raw: "raw string"
  json: {}
  xml: {}  # Future
```

**Inheritance in nested steps:**

```yaml
- name: "User operations"
  request:
    url: "/users"
    headers:
      Authorization: "Bearer {{ auth_token }}"
  steps:
  - name: "Create user"
    request:
      method: POST          # Inherits url and headers
      json: {name: "Test"}
  
  - name: "Get specific user"
    request:
      url: "/users/{{ user_id }}"  # Overrides parent url
      method: GET                   # Inherits headers
```

**Inheritance rules:**

- `base_url` - Child overrides parent
- `url` - Child overrides parent
- `method` - Child overrides parent
- `headers` - Child **merges** with parent (child wins conflicts)
- `query` - Child **merges** with parent (child wins conflicts)

---

## Expectations

### `expect` (Array)

Defines assertions against the response. Each array item is a separate test that runs independently.

```yaml
expect:
- name: "Success response"     # Optional - describes what you're testing
  status: 200                   # Expected HTTP status
  headers: {}                   # Expected headers
  
  # Body validation - choose one approach:
  raw: ""                       # Validate raw string response
  json: {}                      # Validate JSON response
```

**Single test with multiple assertions:**

```yaml
expect:
- status: 201
  headers:
    Location: "/users/123"
  json:
    shape:
      id: integer
      name: string
```

**Multiple separate tests:**

```yaml
expect:
- status: 200
- json:
    shape:
      id: "{{ kind_of.integer }}"
- headers:
    Content-Type: "application/json"
```

---

### JSON Validation Modes

SpecForge provides two modes for validating JSON responses: **simple mode** (`shape`) for everyday testing and **advanced mode** (`schema`) for edge cases.

#### Simple Mode: `shape`

The `shape` keyword handles 85% of real-world API responses with minimal syntax. Use this for validating object structures and array patterns.

**Flat object validation:**

```yaml
# Response: {"id": 123, "email": "alice@test.com", "active": true}
expect:
- json:
    shape:
      id: integer
      email: string
      active: boolean
```

**Nested objects:**

```yaml
# Response: {"id": 1, "user": {"name": "Alice", "role": "admin"}}
expect:
- json:
    shape:
      id: integer
      user:
        name: string
        role: string
```

**Arrays of objects (the most common pattern):**

```yaml
# Response: [{"id": 1, "name": "Alice"}, {"id": 2, "name": "Bob"}]
expect:
- json:
    shape:
      - id: integer
        name: string
```

**Arrays of primitives:**

```yaml
# Response: {"tags": ["ruby", "api", "testing"]}
expect:
- json:
    shape:
      tags: [string]
```

**Nested arrays in objects:**

```yaml
# Response: {"total": 50, "users": [{"id": 1}, {"id": 2}]}
expect:
- json:
    shape:
      total: integer
      users:
        - id: integer
          email: string
          created_at: string
```

**Paginated API responses:**

```yaml
# Response: {"data": [{...}, {...}], "page": 2, "has_more": true}
expect:
- json:
    shape:
      data:
        - id: integer
          title: string
      page: integer
      total: integer
      has_more: boolean
```

**Deep nesting with arrays:**

```yaml
# GitHub-style pull request response
expect:
- json:
    shape:
      - id: integer
        title: string
        user:
          login: string
        labels:
          - name: string
            color: string
```

**Nullable fields:**

```yaml
expect:
- json:
    shape:
      id: integer
      name: string
      middle_name: ?string      # Can be string or null
      metadata: ?hash           # Can be hash or null
```

**Fields named "type" (no conflict in simple mode!):**

```yaml
# Response: {"type": "error", "message": "Invalid request"}
expect:
- json:
    shape:
      type: string              # Just a regular field
      message: string
```

---

#### Advanced Mode: `schema`

The `schema` keyword provides explicit control for edge cases that simple mode can't handle:

1. Positional/tuple arrays (where order matters)
2. When you want to be very explicit about structure
3. Complex validation scenarios

**Positional array (tuple):**

```yaml
# Response: [200, "OK", {"success": true}]
expect:
- json:
    schema:
      type: array
      structure:
        - integer       # First item must be integer
        - string        # Second item must be string
        - hash          # Third item must be hash
```

**Webhook payload with event tuple:**

```yaml
# Response: [1640000000, "user.created", {"user_id": 123}]
expect:
- json:
    schema:
      type: array
      structure:
        - integer       # Timestamp
        - string        # Event type
        - hash          # Payload data
```

**Explicit pattern definition:**

```yaml
# When you want to be very explicit about array patterns
expect:
- json:
    schema:
      type: hash
      structure:
        users:
          type: array
          pattern:
            type: hash
            structure:
              id: integer
              name: string
```

**Mixed validation (simple structure with schema pattern):**

```yaml
# Sometimes you need both!
expect:
- json:
    shape:
      total: integer
    schema:
      type: hash
      structure:
        users:
          type: array
          structure:
            - integer   # User ID
            - string    # User name
            - boolean   # Is active
```

---

### Size Validation

Validate array lengths using the `size` attribute:

```yaml
# Exact size
expect:
- json:
    size: 5
    shape:
      - id: integer

# With matchers
expect:
- json:
    size:
      be.greater_than: 3
    shape:
      - id: integer
```

---

### Content Validation

Use `content` to validate specific values alongside structure:

```yaml
expect:
- json:
    shape:
      id: integer
      status: string
    content:
      id: 42                    # Exact value
      status: "active"          # Exact value
      created_at: "{{ kind_of.string }}"  # Matcher
```

**With arrays:**

```yaml
expect:
- json:
    shape:
      - id: integer
        name: string
    content:
      - id: 1
        name: "Alice"
      - id: 2
        name: "Bob"
```

---

### Recursive/Deep Structures

For recursive data like comment threads, validate to a reasonable depth then punt:

```yaml
# Response: Comments with nested replies
expect:
- json:
    shape:
      - id: integer
        text: string
        replies:
          - id: integer
            text: string
            replies: array    # Just validate it's an array, don't go deeper
```

This mirrors how you'd test recursion manually - check a few levels deep, then trust the pattern continues.

---

### Type Reference

Available types for validation:

- `string`, `?string` - Text values
- `integer`, `?integer` - Whole numbers
- `float`, `?float` - Decimal numbers
- `number`, `?number` - Either integer or float (alias: `numeric`)
- `boolean`, `?boolean` - true/false (alias: `bool`)
- `array`, `?array` - Arrays
- `hash`, `?hash` - Objects (alias: `object`)
- `null`, `nil` - Explicitly null/nil

The `?` prefix makes any type nullable - allowing either the type or null.

---

### When to Use Which Mode

**Use `shape` (simple mode) when:**

- Validating object responses (most REST APIs)
- Testing arrays where all items match the same pattern
- You want clean, readable validation
- Your API doesn't use positional arrays

**Use `schema` (advanced mode) when:**

- Testing positional/tuple arrays where order matters
- You need very explicit control over structure
- You prefer verbose, unambiguous definitions

**Pro tip:** Start with `shape`. Only reach for `schema` when you hit something simple mode can't handle!

---

## Store

### `store` (Hash)

Context-driven keyword with two behaviors:

**Without `request:`** - Sets values (like variables):

```yaml
- store:
    email: "test@example.com"
    password: "pass123"
    config:
      api_version: "v2"
```

**With `request:`** - Captures from response:

```yaml
- request:
    path: /login
    method: POST
  store:
    auth_token: "{{ response.body.token }}"
    user_id: "{{ response.body.user.id }}"
```

**Sequential availability** - Values only available after definition:

```yaml
- store:
    email: "test@test.com"

- name: "Register with {{ email }}"  # ✅ Works
  request:
    json:
      email: "{{ email }}"

- name: "Login with {{ password }}"  # ❌ Error - undefined
```

**Accessing stored values:**

```yaml
path: "/users/{{ user_id }}"
headers:
  Authorization: "Bearer {{ auth_token }}"
json:
  email: "{{ email }}"
```

---

## Callbacks

### `call` (String or Hash)

Immediately executes callback(s) at this point in the sequence. Unlike `hooks`, which schedule callbacks for later, `call` runs them right now.

**Single callback:**

```yaml
- call: seed_test_data

- name: "Test with seeded data"
  request: ...
```

**With arguments:**

```yaml
- call:
    name: seed_database
    arguments:
      count: 50
      type: "posts"

- call:
    name: run_migration
    arguments: [up, version_123]  # Positional
```

### Defining Callbacks

Callbacks are defined in `forge_helper.rb`:

```ruby
SpecForge.configure do |config|
  # Simple callback - no args
  config.register_callback("seed_test_data") do |context|
    # ...
  end
  
  # With keyword args
  config.register_callback("seed_database") do |context, count:, type:|
    # ...
  end
  
  # With positional args
  config.register_callback("run_migration") do |context, direction, version|
    # ...
  end
end
```

**Context parameter:**

The `context` parameter provides access to:

- `context.step` - Current step being executed
- `context.blueprint` - Current blueprint
- `context.store` - Stored values from previous steps
- Other runtime state

---

## Grouping Steps

### `steps` (Array)

Creates nested hierarchy with shared configuration. **At load-time**, flattened into sequential steps with inherited config stamped on each.

```yaml
- name: "User CRUD operations"
  request:
    url: "/users"
    headers:
      Authorization: "Bearer {{ auth_token }}"
  steps:
  - name: "Create user"
    request:
      method: POST
      json: {name: "Test User"}
    store:
      user_id: "{{ response.body.id }}"
      
  - name: "Update user"
    request:
      url: "/users/{{ user_id }}"
      method: PUT
      json: {name: "Updated"}
      
  - name: "Delete user"
    request:
      url: "/users/{{ user_id }}"
      method: DELETE
```

**After loading**, runtime sees:

```ruby
Step(
  name: "Create user",
  request: {
    url: "/users",
    method: "POST",
    headers: {Authorization: "Bearer ..."},
    json: {name: "Test User"}
  }
)
Step(
  name: "Update user",
  request: {
    url: "/users/42",
    method: "PUT",
    headers: {Authorization: "Bearer ..."},
    json: {name: "Updated"}
  }
)
# etc...
```

No parent-child relationship exists at runtime - just flat sequential steps with baked-in config.

---

## Including Files

### `include` (Array)

**Load-time directive** that injects steps from other blueprints. By runtime, included steps are indistinguishable from locally defined ones.

**Allowed attributes:**

- `include:` - File path(s) to inject (required)
- `tags:` - Tags applied to all included steps (optional)
- `name:` - Documentation only (optional)

**Not allowed:**

- Any config attributes (`request`, `store`, `hooks`, etc.) → Error

```yaml
# ✅ Valid - tags are organizational metadata
- include: 
  - auth_setup.yml
  - database_seed.yml
  tags: [bootstrap, setup]

# ✅ Valid - name is just documentation
- name: "Load authentication flow"
  include: auth_setup.yml
  tags: [auth]

# ❌ Error - can't modify included steps' behavior
- include: auth_setup.yml
  request:
    headers:
      X-Custom: "value"
```

**If you need shared config**, use `steps` nesting:

```yaml
- name: "Authenticated operations"
  request:
    headers:
      Authorization: "{{ token }}"
  steps:
  - include: user_operations.yml  # All inherit the header
  - include: post_operations.yml  # These too
```

**How it works:**

```yaml
# What you write in main.yml
- include: auth_setup.yml
  tags: [bootstrap]

- name: "Create resource"
  request: ...
```

```yaml
# What's in auth_setup.yml
- name: "Login"
  request:
    path: /login
  store:
    token: "{{ response.body.token }}"
```

**After loading:**

```ruby
Blueprint(
  steps: [
    Step(name: "Login", tags: ["bootstrap"], ...),
    Step(name: "Create resource", ...)
  ]
)
```

The include vanished - replaced with actual steps from the file.

---

## Tags and Filtering

Tags organize steps for selective execution. They cascade down through nesting and get applied to included files.

### The `tags` Attribute

```yaml
- name: "User CRUD"
  tags: [users, crud]
  steps:
  - name: "Create"
    tags: [write]
    # Effective tags: [users, crud, write]
    
  - name: "Read"
    tags: [read]
    # Effective tags: [users, crud, read]
```

### Tags with Includes

```yaml
# auth_setup.yml
- name: "Login"
  tags: [auth, login]

# main.yml
- include: auth_setup.yml
  tags: [bootstrap]
  # Login now has: [auth, login, bootstrap]
```

### CLI Filtering

```bash
# Run steps with ANY of these tags (OR logic)
spec_forge run --tags smoke
spec_forge run --tags "smoke,auth"

# Skip steps with these tags
spec_forge run --skip-tags slow

# Combine
spec_forge run --tags smoke --skip-tags integration

# File + tags
spec_forge run users.yml --tags smoke
```

**Tag precedence:** `--skip-tags` wins over `--tags` on conflicts.

### Common Patterns

```yaml
# By test type
tags: [smoke, regression, integration]

# By lifecycle
tags: [setup, teardown, cleanup]

# By feature
tags: [auth, users, posts]

# By speed
tags: [fast, slow]

# For documentation
tags: [skip-docs, internal]
```

---

## Special Features

### Data Generation

#### `generate.array`

Creates arrays of arbitrary size for testing:

```yaml
json:
  discord_ids:
    generate.array:
      size: 101
      value: "{{ faker.string.alphanumeric }}"
```

**With template:**

```yaml
generate.array:
  size: 50
  template: "user_{{ index }}"  # index available in template
```

---

## Directory Structure

### Blueprints Directory

SpecForge 1.0 stores workflows in `blueprints/` (replacing 0.7.0's `specs/`).

```
project/
├── blueprints/
│   ├── users_workflow.yml
│   ├── posts_workflow.yml
│   └── auth_setup.yml
└── forge_helper.rb
```

**Why "blueprints"?**

The name reflects the step-based architecture and forge theme. Your YAML files are blueprints - sequential plans that guide SpecForge through forging your API tests.

**Running blueprints:**

```bash
# Default - runs all blueprints in blueprints/
spec_forge run

# With filtering
spec_forge run --tags smoke

# Specific blueprint (explicit path required)
spec_forge run blueprints/users_workflow.yml

# Subdirectory
spec_forge run blueprints/integration/

# Custom location
spec_forge run custom_blueprints/test.yml
```

---

## Test Output and Verbosity

SpecForge provides four verbosity levels to balance quick feedback with detailed debugging information. The output adapts based on whether tests pass or fail, showing only what you need when you need it.

### Verbosity Levels

**Default (non-verbose)**

Minimal output optimized for CI and quick feedback. Shows progress as dots, only expands failures with enough detail to identify the problem.

```bash
spec_forge run
```

**Output when passing:**
```
Running simple_lifecycle.yml...
........

Finished in 0.011s
8 steps, 0 failures
```

**Output when failing:**
```
Running simple_lifecycle.yml...
...F....

Failures:

  1) [simple_lifecycle:08] Create a user
     Expect 3: ✗ (1/3 failed)
       JSON size
         expected: 3
         got: 5

Finished in 0.011s
8 steps, 1 failure

Run with -vv to see full request/response context
```

**`-v` (verbose)**

Shows all steps as they execute with detailed expectation results. Failures display expected vs actual values.

```bash
spec_forge run -v
```

**Output:**
```
[simple_lifecycle:08] Create a user *********************************************
  → POST /api/users
    Expect 1: ✓ (1/1 passed)
    Expect 2: ✓ (2/2 passed)
    Expect 3: ✗ (1/3 failed)
      JSON size
        expected: 3
        got: 5
  ▸ Store "user_id"
  ▸ Store "created_email"
```

**`-vv` (very verbose)**

Adds full request and response context for failed expectations. Shows complete HTTP exchange, variable state, and timing for failures only.

```bash
spec_forge run -vv
```

**Output:**
```
[simple_lifecycle:08] Create a user *********************************************
  → POST /api/users
    Expect 1: ✓ (1/1 passed)
    Expect 2: ✓ (2/2 passed)
    Expect 3: ✗ (1/3 failed)
      ✓ Status: 201
      ✗ JSON size
        expected: 3
        got: 5
      ✓ Headers: Content-Type
      
      Request:
        POST /api/users
        Headers:
          Content-Type: application/json
        Body:
          {
            "name": "John Doe",
            "email": "john@example.com"
          }
      
      Response:
        Status: 201
        Body:
          {
            "id": 42,
            "name": "John Doe",
            "email": "john@example.com",
            "created_at": "2025-01-01T12:00:00Z",
            "updated_at": "2025-01-01T12:00:00Z"
          }
      
      Variables:
        user_id: nil
        created_email: "test@example.com"
      
      Timing: 145ms
```

**`-vvv` (maximum verbosity)**

Shows everything for every step, regardless of success or failure. Use this to trace execution flow and debug complex interactions between steps.

```bash
spec_forge run -vvv
```

**Output includes full details for all steps:**
```
[simple_lifecycle:08] Create a user *********************************************
  → POST /api/users
    Expect 1: ✓ (1/1 passed)
      ✓ Status: 201
      
      Request:
        POST /api/users
        Body: { "name": "John Doe" }
      
      Response:
        Status: 201
        Body: { "id": 42, "name": "John Doe" }
      
      Variables:
        auth_token: "abc123"
      
      Timing: 87ms
```

### Expectation Output

Expectations are grouped by their YAML block and show a summary count before expanding on failures.

**Success (all levels with `-v` or higher):**
```
Expect 1: ✓ (1/1 passed)
Expect 2: ✓ (2/2 passed)
Expect 3: ✓ (3/3 passed)
```

**Failure at `-v`:**
```
Expect 3: ✗ (1/3 failed)
  JSON size
    expected: 3
    got: 5
```

**Failure at `-vv`:**
```
Expect 3: ✗ (1/3 failed)
  ✓ Status: 201
  ✗ JSON size
    expected: 3
    got: 5
  ✓ Headers: Content-Type
  
  [Full request/response context follows]
```

### Debug Mode

For complex debugging scenarios, use the `debug` attribute to drop into an interactive session:

```yaml
- name: "Problematic step"
  debug: true
  request:
    path: /api/users
```

Configure the debug handler in `forge_helper.rb`:

```ruby
SpecForge.configure do |config|
  config.on_debug { binding.pry }
end
```

This gives you full access to inspect variables, the response object, and step context interactively.

### CI/CD Considerations

- **Default mode** works cleanly in CI logs without terminal control sequences
- **`-v`** provides enough detail for most CI debugging scenarios
- **`-vv`** shows full context when CI failures need deeper investigation
- **`-vvv`** generates extensive output - use sparingly in CI

### Usage Patterns

**Quick local development:**
```bash
spec_forge run              # Default, scan for failures
```

**Debugging a specific failure:**
```bash
spec_forge run -vv          # See full request/response for failures
```

**Tracing execution flow:**
```bash
spec_forge run -vvv         # See everything, everywhere
```

**Interactive debugging:**
```yaml
- debug: true               # Drop into Pry/debugger
```

---

## Error Messages

### Structure Definitions

When defining normalizer structures, enhance error messages with optional documentation:

```ruby
http_verb:
  type: string
  validator: http_verb
  description: |-
    The HTTP method to use for the request. Common methods include GET for 
    retrieving data, POST for creating resources, and DELETE for removing resources.
  examples:
    - "GET"
    - "POST"
    - "PATCH"
    - "DELETE"
```

**Enhanced error output:**

```
Invalid HTTP verb "INVALID" for "http_verb" in user spec:
  Expected: String matching one of ["GET", "POST", "PUT", "PATCH", "DELETE"]
  Got: "INVALID"

About http_verb:
  The HTTP method to use for the request. Common methods include GET for 
  retrieving data, POST for creating resources, and DELETE for removing resources.
  
  Examples: "GET", "POST", "PATCH", "DELETE"
```

**When to use:**

- `description` - What it does and when to use it
- `examples` - 3-5 actual valid values (not placeholders)

**When to skip:**

- Self-explanatory attributes (`name`, `debug`)
- Internal implementation details
- Already documented in user-facing docs

---

## Complete Examples

### Simple CRUD Workflow

```yaml
- hooks:
    before_file: clean_database
    after_file: clean_database

- store:
    user_email: "test@example.com"
    user_password: "testpass123"

- name: "Register new user"
  request:
    path: /register
    method: POST
    json:
      email: "{{ user_email }}"
      password: "{{ user_password }}"
  expect:
  - status: 201
    json:
      structure:
        message: string

- name: "Login"
  request:
    path: /login
    method: POST
    json:
      email: "{{ user_email }}"
      password: "{{ user_password }}"
  expect:
  - status: 200
    json:
      structure:
        auth_token: string
  store:
    auth_token: "{{ response.body.auth_token }}"

- name: "Create post"
  request:
    path: /posts
    method: POST
    headers:
      Authorization: "Bearer {{ auth_token }}"
    json:
      title: "My Post"
      content: "Post content"
  expect:
  - status: 201
    json:
      content:
        title: "My Post"
        id: "{{ kind_of.integer }}"
  store:
    post_id: "{{ response.body.id }}"

- name: "Update post"
  request:
    path: "/posts/{{ post_id }}"
    method: PUT
    headers:
      Authorization: "Bearer {{ auth_token }}"
    json:
      title: "Updated Title"
  expect:
  - status: 200
    json:
      content:
        title: "Updated Title"

- name: "Delete post"
  request:
    path: "/posts/{{ post_id }}"
    method: DELETE
    headers:
      Authorization: "Bearer {{ auth_token }}"
  expect:
  - status: 200
```

### Complex Batch API with Nullable Fields

```yaml
- store:
    api_token: "{{ env.API_TOKEN }}"

- name: "Lookup users by steam UIDs"
  request:
    url: /api/v1/users
    headers:
      Authorization: "{{ api_token }}"
    json:
      steam_uids:
      - "steam_id_1"
      - "steam_id_2"
  expect:
  - status: 200
    json:
      size: 2
      structure:
      - steam_uid: string
        discord_id: ?string
      content:
      - steam_uid: "steam_id_1"
        discord_id: "{{ kind_of.string }}"
      - steam_uid: "steam_id_2"
        discord_id: null

- name: "Combined lookup"
  request:
    url: /api/v1/users
    headers:
      Authorization: "{{ api_token }}"
    json:
      steam_uids: ["id1", "id2"]
      discord_ids: ["id3", "id4"]
  expect:
  - status: 200
    json:
      size: 4
      structure:
      - steam_uid: ?string
        discord_id: ?string

- name: "Batch size limit error"
  request:
    url: /api/v1/users
    headers:
      Authorization: "{{ api_token }}"
    json:
      discord_ids:
        generate.array:
          size: 101
          value: "{{ faker.string.alphanumeric }}"
  expect:
  - status: 413
    json:
      structure:
        error: string
      content:
        error: "Request payload too large"

- name: "Invalid request error"
  request:
    url: /api/v1/users
    headers:
      Authorization: "{{ api_token }}"
    json:
      discord_ids: {}  # Should be array
  expect:
  - status: 400
    json:
      structure:
        error: string
```

### Grouped Operations with Shared Config

```yaml
- include: auth_setup.yml

- name: "Comment operations"
  request:
    headers:
      Authorization: "Bearer {{ auth_token }}"
  steps:
  - name: "Create post for comments"
    request:
      url: /posts
      method: POST
      json:
        title: "Test Post"
    store:
      post_id: "{{ response.body.id }}"
  
  - name: "Add comment"
    request:
      url: "/posts/{{ post_id }}/comments"
      method: POST
      json:
        message: "Test comment"
    store:
      comment_id: "{{ response.body.id }}"
  
  - name: "Update comment"
    request:
      url: "/posts/{{ post_id }}/comments/{{ comment_id }}"
      method: PUT
      json:
        message: "Updated comment"
    expect:
    - status: 200
      json:
        content:
          message: "Updated comment"
  
  - name: "Delete comment"
    request:
      url: "/posts/{{ post_id }}/comments/{{ comment_id }}"
      method: DELETE
    expect:
    - status: 200
```
