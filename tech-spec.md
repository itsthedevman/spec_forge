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
- [Grouping Steps](#grouping-steps)
- [Including Files](#including-files)
- [Tags and Filtering](#tags-and-filtering)
- [Callbacks and Hooks](#callbacks-and-hooks)
- [Directory Structure](#directory-structure)
- [Test Output and Verbosity](#test-output-and-verbosity)
- [Error Messages](#error-messages)
- [Global Headers (Why They Don't Exist)](#global-headers-why-they-dont-exist)
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
- hook:
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

The following prefixes trigger special behavior:

|Namespace|Purpose|Example Usage|
|---|---|---|
|`faker.`|Generate fake data|`"{{ faker.name.first_name }}"` or `faker.number.between:`|
|`factories.`|Use FactoryBot|`"{{ factories.user.id }}"` or `factories.user:`|
|`generate.`|Generate arbitrary data|`generate.array:`|
|`env.`|Environment variables|`"{{ env.API_TOKEN }}"`|
|`kind_of.`|Type matchers|`"{{ kind_of.string }}"`|
|`matcher.`|RSpec matchers|`"{{ matcher.eq }}"` or `matcher.include:`|
|`be.`|Predicate matchers|`"{{ be.true }}"` or `be.greater_than:`|
|`transform.`|Data transformations|`transform.join:`|

See [String Interpolation](#string-interpolation) for position-based syntax rules.

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

### Data Generation

**`generate.array`** - Creates arrays of arbitrary size for testing:

```yaml
json:
  discord_ids:
    generate.array:
      size: 101
      value: "{{ faker.string.alphanumeric }}"
```

**With sequential values:**

The special variable `index` (0-based) is available within `value` expressions:

```yaml
generate.array:
  size: 50
  value: "user_{{ index }}"  # Generates: user_0, user_1, ..., user_49
```

**Combined patterns:**

```yaml
generate.array:
  size: 10
  value: "{{ faker.internet.username }}_{{ index }}"  # random_user_0, random_user_1, ...
```

**Note:** `index` is a reserved keyword during array generation and will override any stored variable with the same name.
```

---

## Step Attributes

Every step is a hash that can contain these attributes:

```
Step
├── name: String (optional)
├── debug: Boolean (optional, default: false)
├── tags: Array<String> (optional, inheritable)
├── documentation: Hash (optional)
├── request: Hash (optional, triggers HTTP behavior)
│   ├── base_url, url, method, headers, query
│   └── raw, json, xml (body formats)
├── expect: Array<Expectation> (optional)
│   └── status, headers, raw, json, xml
├── store: Hash (optional, context-driven)
├── call: String or Hash (optional)
├── hook: Hash (optional, lifecycle events)
├── steps: Array<Step> (optional, load-time only)
└── include: Array<String> (optional, load-time only)
```

**Load-time only** (gone by runtime):
- `include` - File injection directive
- `steps` - Hierarchy flattened to sequential steps

**Modified at load-time:**
- `tags` - Inherited from parents
- `request` - Merged with parent config

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

- `base_url`, `url`, `method` - Child overrides parent
- `headers`, `query` - Child **merges** with parent (child wins conflicts)

---

## Expectations

### `expect` (Array)

Defines assertions against the response. Each array item is a separate test that runs independently.

```yaml
expect:
- name: "Success response"     # Optional
  status: 200                   # Expected HTTP status
  headers: {}                   # Expected headers
  raw: ""                       # Validate raw string
  json: {}                      # Validate JSON
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

SpecForge provides two modes: **simple mode** (`shape`) for everyday testing and **advanced mode** (`schema`) for edge cases.

#### Simple Mode: `shape`

Handles 85% of real-world API responses with minimal syntax.

**Basic structures:**

```yaml
# Flat object: {"id": 123, "email": "alice@test.com", "active": true}
expect:
- json:
    shape:
      id: integer
      email: string
      active: boolean
      
# Nested object: {"id": 1, "user": {"name": "Alice", "role": "admin"}}
expect:
- json:
    shape:
      id: integer
      user:
        name: string
        role: string
```

**Arrays (most common pattern):**

```yaml
# Array of objects: [{"id": 1, "name": "Alice"}, {"id": 2, "name": "Bob"}]
expect:
- json:
    shape:
      - id: integer
        name: string

# Array of primitives: {"tags": ["ruby", "api", "testing"]}
expect:
- json:
    shape:
      tags: [string]
```

**Paginated responses:**

```yaml
# {"data": [{...}, {...}], "page": 2, "has_more": true}
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

**Deep nesting:**

```yaml
# GitHub-style pull request
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

---

#### Advanced Mode: `schema`

Provides explicit control for edge cases:

1. Positional/tuple arrays (where order matters)
2. When you want to be very explicit about structure
3. Complex validation scenarios

**Positional array (tuple):**

```yaml
# [200, "OK", {"success": true}]
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
# [1640000000, "user.created", {"user_id": 123}]
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
      id: 42
      status: "active"
      created_at: "{{ kind_of.string }}"
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
# Comments with nested replies
expect:
- json:
    shape:
      - id: integer
        text: string
        replies:
          - id: integer
            text: string
            replies: array    # Just validate it's an array
```

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

The `?` prefix makes any type nullable.

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

**After loading**, runtime sees flat sequential steps with baked-in config - no parent-child relationship exists.

---

## Including Files

### `include` (Array)

**Load-time directive** that injects steps from other blueprints. By runtime, included steps are indistinguishable from locally defined ones.

**Allowed attributes:**

- `include:` - File path(s) to inject (required)
- `tags:` - Tags applied to all included steps (optional)
- `name:` - Documentation only (optional)

**Not allowed:**

- Any config attributes (`request`, `store`, `hook`, etc.) → Error

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

## Callbacks and Hooks

SpecForge provides two mechanisms for executing code at specific points: **named callbacks** (user-controlled) and **lifecycle hooks** (framework-level).

### Named Callbacks

Named callbacks are registered in `forge_helper.rb` and invoked explicitly from YAML using the `hook:` attribute or `call:` step attribute.

**Registration:**

```ruby
SpecForge.configure do |config|
  # Simple callback - no arguments
  config.register_callback(:seed_database) do |context|
    User.create!(email: "test@test.com")
  end
  
  # With keyword arguments
  config.register_callback(:create_records) do |context, count:, type:|
    count.times { type.constantize.create! }
  end
  
  # With positional arguments
  config.register_callback(:run_migration) do |context, direction, version|
    # ...
  end
end
```

**Usage in YAML:**

```yaml
# Inline execution with call:
- call: seed_database

# Lifecycle hooks
hook:
  before_blueprint: seed_database
  after_blueprint: cleanup_database
  
# With arguments
hook:
  before_blueprint:
    name: create_records
    arguments:
      count: 50
      type: "User"
```

### Lifecycle Hooks

Lifecycle hooks execute callbacks at specific framework events. Hooks are defined in YAML using the `hook:` attribute and are processed during load-time into three distinct scopes.

#### Hook Scopes

**Forge-level hooks** - Execute once per test run:
- `before_forge` - Runs once before any blueprints execute
- `after_forge` - Runs once after all blueprints complete

**Blueprint-level hooks** - Execute once per blueprint file:
- `before_blueprint` - Runs once before the first step in a blueprint
- `after_blueprint` - Runs once after the last step in a blueprint

**Step-level hooks** - Execute around each step:
- `before_step` - Runs before each step executes
- `after_step` - Runs after each step completes (even if step failed)

#### Load-time Processing

During load-time, the `hook:` attribute is extracted from steps and organized by scope. **Important:** Hooks defined on a step affect that step itself - they're stamped onto the step during processing.

```yaml
# YAML input
- hook:
    before_forge: setup_env
    before_blueprint: seed_db
    before_step: log_start
  name: "First step"
  request: ...
```

This is functionally equivalent to:

```yaml
# What actually executes
- call: setup_env     # before_forge
- call: seed_db       # before_blueprint
- call: log_start     # before_step
- name: "First step"
  request: ...
```

**After processing:**

- **Forge hooks:** `{before: [setup_env], after: []}`  
  Collected from all blueprints, deduplicated by callback name

- **Blueprint hooks:** `{before: [seed_db], after: []}`  
  Collected from all steps in the file, deduplicated by callback name

- **Step hooks:** `{before: [log_start], after: []}`  
  Stamped onto the step that defined them

#### Hook Inheritance with `shared:`

Step-level hooks can be inherited by nested steps using the `shared:` wrapper. This makes inheritance visually explicit:

```yaml
# Blueprint-level hook (affects all subsequent steps)
- hook:
    before_step: global_logger

# Section-level hook (only affects nested steps)
- name: "Auth workflows"
  tags: [auth]           # Metadata - auto-cascades
  shared:                # Behavior inheritance wrapper
    request:
      headers:
        Authorization: "{{ token }}"
    hook:
      before_step: auth_logger
  steps:
    - name: "Login"      # Gets global_logger + auth_logger + inherits request
    - name: "Logout"     # Gets global_logger + auth_logger + inherits request

# Another section (doesn't inherit auth stuff)
- name: "User workflows"
  steps:
    - name: "Create user"  # Gets global_logger only
```

**The `shared:` wrapper contains:**
- `request` - HTTP configuration that substeps inherit
- `hook` - Lifecycle callbacks that substeps inherit

**Inheritance rules:**
- Hooks in `shared:` accumulate with parent hooks (never replace)
- Execution order is parent-to-child (outer hooks run first)
- Hooks are scoped to their subtree - sibling sections don't inherit each other's hooks
- Tags auto-cascade (they're metadata, not in `shared:`)

**Nested accumulation:**

```yaml
- hook:
    before_step: outer_logger
  
- name: "Section"
  shared:
    hook:
      before_step: middle_logger
  steps:
  - name: "Subsection"
    shared:
      hook:
        before_step: inner_logger
    steps:
    - name: "Deep step"
      # Effective hooks: {before: [outer_logger, middle_logger, inner_logger], after: []}
```

#### Action + Steps Restriction

Following Ansible's design principle, you cannot combine action attributes with `steps:`. A step either executes an action OR organizes substeps, not both.

**Action attributes** (cannot combine with `steps:`):
- `request` - Executes HTTP call
- `expect` - Validates response  
- `call` - Executes callback
- `debug` - Triggers breakpoint
- `store` - Sets variables

**This is an error:**
```yaml
# ❌ Error at load-time
- name: "Section"
  request: ...       # Can't mix action with steps
  steps: [...]
```

**Instead, use `shared:` for inheritance:**
```yaml
# ✅ Use shared wrapper
- name: "Section"
  shared:
    request: ...     # Substeps inherit this
  steps: [...]
```

**Or separate steps:**
```yaml
# ✅ Execute then organize
- request: ...       # Execute action
- name: "Section"    # Then organize substeps
  steps: [...]
```

#### Deduplication

Hooks are deduplicated by callback name at each scope to prevent duplicate execution:

```yaml
# Both steps define the same blueprint hook
- hook:
    before_blueprint: seed_db
    
- hook:
    before_blueprint: seed_db  # Only runs once!
```

Deduplication applies at all three scopes:
- **Forge hooks** - If multiple blueprints define `before_forge: setup_env`, it runs once
- **Blueprint hooks** - If multiple steps define `before_blueprint: seed_db`, it runs once
- **Step hooks** - If the same callback appears multiple times in the accumulation chain, it runs once per step

#### Runtime Execution

Hooks execute at their designated lifecycle points:

**Forge lifecycle:**
```
before_forge hooks
  Blueprint 1
    before_blueprint hooks
      Step 1
        before_step hooks
        [step actions]
        after_step hooks
      Step 2...
    after_blueprint hooks
  Blueprint 2...
after_forge hooks
```

**Step execution detail:**
```
before_step hooks
  call: actions
  request: action
  debug: action
  expect: actions
  store: actions
after_step hooks
```

### Global Hooks

Global hooks attach callbacks to framework lifecycle events. They run for all blueprints and cannot be controlled from YAML. Callbacks must be registered before being attached to hooks.

**Registration:**

```ruby
SpecForge.configure do |config|
  # Define the callbacks first
  config.register_callback(:start_cleaner) do |context|
    DatabaseCleaner.start
  end
  
  config.register_callback(:log_step) do |context, step:|
    logger.info("Completed: #{step.name}")
  end
  
  config.register_callback(:cleanup) do |context|
    DatabaseCleaner.clean
  end
  
  # Attach them to lifecycle events
  config.before(:forge, :start_cleaner)
  config.after(:step, :log_step)
  config.after(:forge, :cleanup)
end
```

**Note:** Callbacks are reusable - the same callback can be attached to multiple events:

```ruby
config.register_callback(:log_event) do |context|
  logger.info("Event triggered")
end

config.before(:forge, :log_event)
config.before(:blueprint, :log_event)
config.before(:step, :log_event)
```

### Available Events

**YAML-accessible events** (via `hook:` attribute):

- `before_blueprint` - Runs once before the first step in a blueprint
- `after_blueprint` - Runs once after the last step in a blueprint
- `before_step` - Runs before each step in a blueprint
- `after_step` - Runs after each step (even if step failed)

**Global events** (via `before/after` only):

- `before(:forge, callback)` - Runs once before any blueprints execute
- `after(:forge, callback)` - Runs once after all blueprints complete
- `before(:blueprint, callback)` - Runs before each blueprint
- `after(:blueprint, callback)` - Runs after each blueprint
- `before(:step, callback)` - Runs before each step
- `after(:step, callback)` - Runs after each step

### YAML Syntax

The `hook:` attribute supports three syntax variations:

**String syntax** (single callback):

```yaml
hook:
  before_blueprint: seed_database
  after_step: log_response
```

**Array syntax** (multiple callbacks):

```yaml
hook:
  before_blueprint:
    - seed_database
    - setup_auth
  after_step:
    - log_response
    - cleanup_cache
```

**With arguments:**

```yaml
hook:
  before_blueprint:
    name: create_records
    arguments:
      count: 50
      type: "User"
      
  after_step:
    name: conditional_cleanup
    arguments: [force, "2024-01-01"]  # Positional
```

### Execution Order

Hooks execute in registration order. Since global hooks are registered before YAML is loaded:

1. Global hooks from `before/after` (in registration order)
2. Named callbacks from YAML `hook:` (in definition order)

**Example:**

```ruby
# forge_helper.rb
config.register_callback(:global_1) { puts "Global hook 1" }
config.register_callback(:global_2) { puts "Global hook 2" }
config.register_callback(:user_hook) { puts "User callback" }

config.after(:step, :global_1)
config.after(:step, :global_2)
```

```yaml
# blueprint.yml
hook:
  after_step: user_hook
```

**Output after each step:**

```
Global hook 1
Global hook 2
User callback
```

### Context Parameter

All callbacks receive a `context` parameter providing access to runtime state:

```ruby
config.register_callback(:log_vars) do |context, step:|
  context.variables  # Current variable state
end

config.after(:step, :log_vars)
```

**Parameters by hook type:**
- `before_forge` / `after_forge` - Receives `context` only
- `before_blueprint` / `after_blueprint` - Receives `context` only  
- `before_step` / `after_step` - Receives `context` and `step:` keyword argument

### Conditional Execution

Callbacks can use guards to execute only for specific step types. The `step` parameter provides predicates for checking step attributes:

```ruby
config.register_callback(:log_requests) do |context, step:|
  next unless step.request?
  
  request = context.variables[:request]
  puts "→ #{request[:http_verb]} #{request[:url]}"
end

config.after(:step, :log_requests)
```

**Available step predicates:**

```ruby
step.call?      # Has call: attribute
step.debug?     # Has debug: true
step.expect?    # Has expect: attribute
step.request?   # Has request: attribute
step.store?     # Has store: attribute
```

**Common patterns:**

```ruby
# Only validate state after requests
config.register_callback(:validate_db_state) do |context, step:|
  next unless step.request?
  # Check database consistency
end

# Log response details only when expectations exist
config.register_callback(:log_validation) do |context, step:|
  next unless step.expect?
  
  response = context.variables[:response]
  puts "Validated: #{response[:status]}"
end

# Skip hooks for specific steps
config.register_callback(:cleanup_cache) do |context, step:|
  next if step.name.include?("Setup")
  Cache.clear
end
```

This gives you full control over when callbacks execute without adding complexity to the hook system itself.

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

## Global Headers (Why They Don't Exist)

**SpecForge 1.0 does not support global headers in configuration.** This is intentional. Here's why and what to use instead:

### The Problem with Global Headers

Global headers create "magic" - someone reading a blueprint can't tell what headers are actually being sent without checking `forge_helper.rb`. This violates the principle that blueprints should be self-documenting.

```yaml
# ❌ This looks like it has no auth, but maybe global config adds it?
- request:
    url: /users
```

### Solution 1: Use Nesting + Inheritance

The cleanest pattern for shared headers is explicit nesting:

```yaml
- name: "Authenticated operations"
  request:
    headers:
      Authorization: "Bearer {{ auth_token }}"
  steps:
  - name: "Create user"
    request:
      url: /users
      method: POST
      
  - name: "Update user"
    request:
      url: /users/{{ user_id }}
      method: PATCH
```

**Benefits:**

- Explicit - you can see exactly what headers are sent
- Self-documenting - no need to check config files
- Scoped - different sections can have different headers

### Solution 2: Use Global Variables

For headers that truly need to be defined once and used everywhere:

```ruby
# forge_helper.rb
SpecForge.configure do |config|
  config.global_variables = {
    auth_header: "Bearer #{ENV['API_TOKEN']}"
  }
end
```

```yaml
# blueprint.yml
- request:
    url: /users
    headers:
      Authorization: "{{ auth_header }}"
```

**Benefits:**

- Headers are still visible in the blueprint
- Token value can be environment-specific
- Easy to override per-blueprint with local variables

### When to Use Which

**Use nesting** when:

- Headers apply to a logical group of operations
- You want the blueprint to be self-contained
- Different sections need different headers

**Use global variables** when:

- The same header value is used across multiple blueprints
- The value depends on environment (dev/staging/prod)
- You need to change the value in one place

**Never try to add global headers to config** - the patterns above handle all real-world cases more explicitly and maintainably.

---

## Complete Examples

### Simple CRUD Workflow

```yaml
- hook:
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
