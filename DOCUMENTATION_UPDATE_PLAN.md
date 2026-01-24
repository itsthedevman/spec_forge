# SpecForge 1.0 Documentation Update Plan

## Overview
This plan outlines the work needed to update all user-facing documentation from version 0.7.x syntax to version 1.0.0. The update includes the README.md in the main repo and all wiki pages in the spec_forge.wiki repository.

## Key Changes in 1.0.0

### Architecture
- **Step-based workflows** instead of spec-based tests
- Sequential execution model with explicit variable flow
- Load-time vs run-time processing phases
- Flattened execution (no hierarchy at runtime)

### Directory Structure
- `spec_forge/specs/` → `spec_forge/blueprints/`
- Same locations for `factories/` and `openapi/`

### Syntax Changes
- **File structure**: Array of step hashes instead of named specs
- **Variable storage**: `store:` attribute (context-driven) replaces `variables:` and `store_as:`
- **Request attribute**: Primary name is `url` (alias: `path`)
- **HTTP method**: Primary name is `http_verb` (alias: `method`)
- **Nesting**: `steps:` attribute for hierarchical organization
- **Inheritance**: `shared:` wrapper for request/hook inheritance
- **Includes**: Cannot combine with config attributes
- **Global variables**: Via `config.global_variables` in forge_helper.rb

### Reserved Namespaces (same concept, different usage)
- `faker.`, `factories.`, `generate.`, `env.`, `kind_of.`, `matcher.`, `be.`, `transform.`
- String interpolation: `{{ variable }}` syntax
- Position-based rules for when to use `{{ }}`

### Commands
- `spec_forge init` - Create project structure
- `spec_forge new blueprint <name>` - Create blueprint file
- `spec_forge new factory <name>` - Create factory file
- `spec_forge run [path]` - Execute blueprints (with filtering options)
- `spec_forge docs` - Generate OpenAPI documentation
- `spec_forge serve` - Generate and serve documentation

### Verbosity Levels (new in 1.0)
- Default: Minimal output (dots)
- `-v`/`--verbose`: Detailed step execution
- `-vv`/`--debug`: Full request/response for failures
- `-vvv`/`--trace`: Everything for all steps

## Documentation Files to Update

### Main Repository

#### 1. README.md
**Priority: HIGH** | **Complexity: Medium**

**Changes needed:**
- Update hero example to use step-based syntax
- Remove old spec syntax examples
- Update "Quick Start" section with correct commands
- Update directory structure (`blueprints/` instead of `specs/`)
- Update CLI commands section
- Modernize examples to use `store:`, `{{ }}` syntax, `url:` instead of `path:`
- Note that OpenAPI generation is an early feature with improvements coming
- Keep "When Not to Use SpecForge" section (still valid)

**Example sections to rewrite:**
- Hero YAML example (lines 11-31)
- Quick Start (lines 69-84)
- Complete User API example (lines 169-224)

---

### Wiki Pages

#### 2. Home.md
**Priority: HIGH** | **Complexity: Low**

**Changes needed:**
- Update hero example to step-based syntax
- Update navigation links (verify all are still valid)
- Ensure feature list is accurate for 1.0

---

#### 3. Getting-Started.md
**Priority: HIGH** | **Complexity: High**

**Changes needed:**
- Update directory structure (`blueprints/` not `specs/`)
- Update CLI commands (`spec_forge new blueprint users`)
- Rewrite "Forging Your First Test" with step-based workflow
- Update dynamic data examples to use `store:` and proper syntax
- Update "Next Steps" links to ensure they're all still relevant

**Key sections to rewrite:**
- Initial Setup (directory names)
- Forging Your First Test (complete rewrite)
- Using Dynamic Data (update syntax)
- Running tests section

---

#### 4. Writing-Tests.md
**Priority: HIGH** | **Complexity: Very High**

**Changes needed:**
- Complete rewrite from scratch
- Document step-based architecture
- Show sequential workflow examples
- Explain `store:` context-driven behavior
- Document `request:` attribute with aliases
- Document `expect:` array with validation modes (shape/schema)
- Show nesting with `steps:` attribute
- Show inheritance with `shared:` wrapper
- Document string interpolation rules
- Document reserved namespaces
- Include complete realistic examples

**New sections needed:**
- Basic Step Structure
- Sequential Execution
- Variable Storage with `store:`
- Request Configuration
- Response Validation (shape vs schema)
- Grouping Steps with Nesting
- Inheritance and Shared Config
- String Interpolation and Reserved Namespaces
- Complete Workflow Examples

---

#### 5. Running-SpecForge.md (rename to Running-Tests.md?)
**Priority: HIGH** | **Complexity: Medium**

**Changes needed:**
- Update all CLI commands to 1.0 syntax
- Document new filtering options (`--tags`, `--skip-tags`)
- Document new verbosity flags (`--verbose`, `--debug`, `--trace`)
- Remove old spec:expectation targeting syntax
- Add blueprint-specific running examples
- Update documentation commands section

**Sections to update:**
- Available Commands
- Running All Tests → `spec_forge run`
- Targeting Specific Tests → blueprint/tag filtering
- Documentation Commands (ensure accuracy)
- Add new "Verbosity Levels" section

---

#### 6. Configuration.md
**Priority: HIGH** | **Complexity: High**

**Changes needed:**
- Update global variables section (now `config.global_variables`)
- Remove global `config.headers` and `config.query` (1.0 doesn't support these - use nesting instead per tech spec)
- Update callback registration examples
- Update debug configuration examples
- Document new config options if any
- Update framework integration section

**Key changes:**
- Global headers explanation (why they don't exist in 1.0)
- Global variables via `config.global_variables`
- Callback registration (verify syntax is same)
- Environment-specific configuration patterns

---

#### 7. Context-System.md
**Priority: HIGH** | **Complexity: Very High**

**Changes needed:**
- Complete rewrite for `store:` attribute
- Document context-driven behavior (with/without `request:`)
- Update global variables section
- Remove old `variables:` and `store_as:` references
- Document variable lookup and shadowing
- Show response extraction examples
- Update all code examples

**New sections:**
- Global Variables (config.global_variables)
- Local Variables (store: attribute)
- Context-Driven Behavior
- Variable Lookup Order
- Response Value Extraction
- Shadowing and Scope

---

#### 8. Callbacks.md
**Priority: MEDIUM** | **Complexity: Medium**

**Changes needed:**
- Update to use `hook:` attribute instead of global callbacks section
- Document hook scopes (forge, blueprint, step)
- Document hook inheritance with `shared:`
- Update lifecycle hook names if changed
- Update all YAML examples to step-based syntax
- Update context data available at each hook
- Verify callback registration syntax

**Sections to verify/update:**
- Lifecycle Hooks (ensure names match: before_forge, after_forge, before_blueprint, after_blueprint, before_step, after_step)
- Hook attribute syntax in YAML
- Hook inheritance
- Context parameter structure
- Example use cases

---

#### 9. Dynamic-Features.md
**Priority: MEDIUM** | **Complexity: High**

**Changes needed:**
- Update all examples to step-based syntax
- Update Faker usage examples (verify namespace usage)
- Update FactoryBot examples to use `factories.` namespace
- Document `generate.array` feature
- Update transformation examples
- Remove `variables:` references, use `store:`

**Sections to update:**
- Using Faker (verify syntax)
- Using Factories (verify syntax)
- Variables System → Variable Storage (rename and update)
- Transformations (update examples)
- Add new section on generate.array

---

#### 10. Factory-Support.md
**Priority: MEDIUM** | **Complexity: Medium**

**Changes needed:**
- Update examples to step-based syntax
- Verify factory namespace syntax (`factories.user`)
- Update YAML factory definition examples if syntax changed
- Update usage examples to use `store:` and `{{ }}`
- Verify factory configuration section

**Sections to update:**
- Using Factories (update examples)
- YAML Factory Definitions (verify syntax)
- All code examples

---

#### 11. Factory-Lists.md
**Priority: LOW** | **Complexity: Medium**

**Changes needed:**
- Update to use `store:` instead of `variables:`
- Update all examples to step-based syntax
- Verify FactoryBot list utility syntax
- Update usage patterns

---

#### 12. RSpec-Matchers.md
**Priority: MEDIUM** | **Complexity: Low**

**Changes needed:**
- Update examples to use `expect:` array format
- Update namespace usage examples (`kind_of.`, `matcher.`, `be.`)
- Verify position-based syntax rules (value vs key position)
- Update code examples to step-based syntax

**Sections to update:**
- Basic Matchers (update examples)
- "be" Namespace (update examples)
- "kind_of" Namespace (update examples)
- "matcher" Namespace (update examples)

---

#### 13. Advanced-Matchers.md
**Priority: MEDIUM** | **Complexity: Low**

**Changes needed:**
- Update compound matcher examples
- Update header testing examples
- Update to step-based syntax

---

#### 14. Documentation-Generation.md
**Priority: MEDIUM** | **Complexity: Medium**

**Changes needed:**
- Add note that this is an early feature with improvements planned
- Update all examples to step-based syntax
- Update CLI commands (`spec_forge docs`, `spec_forge serve`)
- Verify OpenAPI configuration structure (should be same per your answer)
- Update workflow examples
- Add note about providing feedback

**Key updates:**
- Opening note: "OpenAPI generation is an early feature. The core functionality works as documented, but we're planning improvements based on user feedback. Please share your thoughts!"
- Update all YAML examples to step-based syntax
- Verify configuration structure
- Update CLI command examples

---

#### 15. Debugging.md
**Priority: LOW** | **Complexity: Low**

**Changes needed:**
- Update examples to step-based syntax
- Update debug attribute usage
- Verify debug configuration
- Update available variables in debug context
- Add information about verbosity flags

---

#### 16. How-Tests-Work.md
**Priority: LOW** | **Complexity: Very High**

**Changes needed:**
- Complete rewrite for load-time vs run-time architecture
- Document flattening process
- Document step stamping and inheritance
- Update pipeline diagrams/explanations
- Document normalizer system if relevant
- This can be done last as you suggested

**New content needed:**
- Load-time Processing
- Run-time Execution
- Step Flattening
- Configuration Inheritance
- Include Resolution
- Tag Cascading

---

#### 17. Contributing.md
**Priority: LOW** | **Complexity: Low**

**Changes needed:**
- Update development setup if changed
- Update directory references
- Verify contribution workflow

---

#### 18. _Sidebar.md
**Priority: MEDIUM** | **Complexity: Low**

**Changes needed:**
- Update navigation structure if pages are renamed
- Ensure all links are valid
- Add new sections if created
- Update section names to match new content

---

### New Documents Needed

#### 19. Migration-Guide.md
**Priority: HIGH** | **Complexity: Very High**

**Create new document with:**
- Overview of changes from 0.7 to 1.0
- Step-by-step migration process
- Before/after examples for each major change
- Directory structure migration
- Syntax conversion guide
- Common pitfalls
- FAQ section

**Sections:**
1. Overview of 1.0 Changes
2. Directory Structure Changes
3. Syntax Changes
   - File Structure
   - Variable Storage
   - Request Configuration
   - Response Validation
   - Nesting and Organization
4. Global Variables Migration
5. Include Statement Changes
6. CLI Command Changes
7. Complete Example Migration
8. Common Pitfalls
9. FAQ

---

## Approach

### Phase 1: High Priority Foundation (Start Here)
**Recommended to tackle 1-2 of these first:**

1. **README.md** - Main entry point, sets expectations
2. **Getting-Started.md** - Critical for new users
3. **Writing-Tests.md** - Core reference for test syntax
4. **Migration-Guide.md** - Critical for existing users

### Phase 2: Core Documentation
5. Configuration.md
6. Context-System.md
7. Running-Tests.md
8. Documentation-Generation.md

### Phase 3: Feature Documentation
9. Callbacks.md
10. Dynamic-Features.md
11. Factory-Support.md
12. RSpec-Matchers.md

### Phase 4: Advanced & Polish
13. Home.md
14. Advanced-Matchers.md
15. Factory-Lists.md
16. Debugging.md
17. How-Tests-Work.md
18. Contributing.md
19. _Sidebar.md

## Quality Standards

### All Documents Must:
- Use factual, realistic examples (no placeholder data like "foo/bar")
- Show complete, runnable code examples
- Use consistent terminology from tech-spec.md
- Use primary attribute names (e.g., `url` not `path`, `http_verb` not `method`)
- Note aliases where helpful
- Include practical use cases
- Follow step-based workflow architecture
- Use proper string interpolation (`{{ variable }}`)

### Example Quality
```yaml
# ✅ GOOD - Realistic, complete, uses primary names
- name: "Login as admin"
  request:
    url: /auth/login
    http_verb: POST
    json:
      email: "admin@test.com"
      password: "admin123"
  store:
    auth_token: "{{ response.body.token }}"

# ❌ BAD - Placeholder data, uses aliases, incomplete
- path: /foo/{bar}
  method: POST
```

## Validation Checklist

Before considering any document complete:
- [ ] All code examples use 1.0 syntax
- [ ] No references to old `specs/` directory
- [ ] No references to `variables:` or `store_as:`
- [ ] All examples are realistic and runnable
- [ ] Uses primary attribute names with aliases noted
- [ ] Follows step-based workflow patterns
- [ ] Links to other wiki pages are valid
- [ ] Examples demonstrate sequential execution model
- [ ] Proper use of string interpolation

## Notes

- OpenAPI generation is same as 0.7, but note it's an early feature
- FactoryBot integration is unchanged in core functionality
- The `shared:` wrapper is key for inheritance (explicit > implicit)
- Global headers don't exist - use nesting or global variables
- Hook system uses `hook:` attribute in YAML
- Compare changes: `git diff aa2bf13..HEAD` for full change history
