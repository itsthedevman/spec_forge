# frozen_string_literal: true

RSpec.describe SpecForge::Attribute::Template do
  let(:input) { "" }

  subject(:attribute) { described_class.new(input) }

  # Helper to set up context and resolve the template
  def resolve_with(vars)
    context = SpecForge::Forge::Context.new(
      variables: SpecForge::Forge::Variables.new(static: vars)
    )

    SpecForge::Forge.with_context(context) do
      attribute.value
    end
  end

  describe "#initialize" do
    context "with a single template expression" do
      let(:input) { "User ID: {{ user_id }}" }

      it "parses the template into placeholder and variable" do
        expect(attribute.instance_variable_get(:@parsed)).to eq("User ID: ⬣→SF0")

        templates = attribute.instance_variable_get(:@templates)
        expect(templates.keys).to eq(["⬣→SF0"])
        expect(templates["⬣→SF0"]).to be_a(SpecForge::Attribute::Variable)
      end
    end

    context "with multiple different expressions" do
      let(:input) { "{{ greeting }} user:{{ user_id }}. Email: {{ email }}" }

      it "creates separate placeholders for each expression" do
        parsed = attribute.instance_variable_get(:@parsed)
        expect(parsed).to eq("⬣→SF0 user:⬣→SF1. Email: ⬣→SF2")

        templates = attribute.instance_variable_get(:@templates)
        expect(templates.size).to eq(3)
      end
    end

    context "with duplicate expressions" do
      let(:input) { "{{ user_id }} and {{ user_id }} again" }

      it "reuses the same placeholder for duplicates" do
        parsed = attribute.instance_variable_get(:@parsed)
        expect(parsed).to eq("⬣→SF0 and ⬣→SF0 again")

        templates = attribute.instance_variable_get(:@templates)
        expect(templates.size).to eq(1)
      end
    end

    context "with whitespace variations" do
      let(:input) { "{{user_id}} vs {{ user_id }} vs {{  user_id  }}" }

      it "treats them all as the same expression" do
        parsed = attribute.instance_variable_get(:@parsed)
        expect(parsed).to eq("⬣→SF0 vs ⬣→SF0 vs ⬣→SF0")

        templates = attribute.instance_variable_get(:@templates)
        expect(templates.size).to eq(1)
      end
    end

    context "with chained variable access" do
      let(:input) { "User: {{ user.name }} has ID {{ user.id }}" }

      it "creates variable attributes with invocation chains" do
        templates = attribute.instance_variable_get(:@templates)

        expect(templates.size).to eq(2)
        expect(templates["⬣→SF0"]).to be_a(SpecForge::Attribute::Variable)
        expect(templates["⬣→SF1"]).to be_a(SpecForge::Attribute::Variable)
      end
    end

    context "with no template expressions" do
      let(:input) { "Just plain text" }

      it "returns empty templates" do
        parsed = attribute.instance_variable_get(:@parsed)
        templates = attribute.instance_variable_get(:@templates)

        expect(parsed).to eq("Just plain text")
        expect(templates).to be_empty
      end
    end
  end

  describe "#value" do
    context "with simple variable substitution" do
      let(:input) { "Hello {{ name }}!" }

      it "substitutes the variable value" do
        result = resolve_with(name: "World")
        expect(result).to eq("Hello World!")
      end
    end

    context "with multiple variables" do
      let(:input) { "{{ greeting }} {{ name }}, you are user \#{{ id }}" }

      it "substitutes all variables" do
        result = resolve_with(greeting: "Hey", name: "Bryan", id: 42)
        expect(result).to eq("Hey Bryan, you are user #42")
      end
    end

    context "with duplicate variable usage" do
      let(:input) { "{{ name }} and {{ name }} both have {{ count }} items" }

      it "substitutes the same variable multiple times" do
        result = resolve_with(name: "Alice", count: 5)
        expect(result).to eq("Alice and Alice both have 5 items")
      end
    end

    context "with chained variable access" do
      let(:input) { "User {{ user.name }} has ID {{ user.id }}" }

      it "resolves nested variable access" do
        result = resolve_with(user: {name: "Bob", id: 123})
        expect(result).to eq("User Bob has ID 123")
      end
    end

    context "with numeric values" do
      let(:input) { "Count: {{ count }}, Price: {{ price }}" }

      it "converts numbers to strings" do
        result = resolve_with(count: 42, price: 19.99)
        expect(result).to eq("Count: 42, Price: 19.99")
      end
    end

    context "with boolean values" do
      let(:input) { "Active: {{ active }}, Enabled: {{ enabled }}" }

      it "converts booleans to strings" do
        result = resolve_with(active: true, enabled: false)
        expect(result).to eq("Active: true, Enabled: false")
      end
    end

    context "with mixed static and dynamic variables" do
      let(:input) { "API: {{ base_url }}/users/{{ user_id }}" }

      it "resolves both global and local variables" do
        vars = SpecForge::Forge::Variables.new(
          static: {base_url: "https://api.example.com"},
          dynamic: {user_id: 99}
        )

        context = SpecForge::Forge::Context.new(variables: vars)

        result = SpecForge::Forge.with_context(context) do
          attribute.value
        end

        expect(result).to eq("API: https://api.example.com/users/99")
      end
    end

    context "with faker attributes" do
      let(:input) { "Name: {{ faker.name.first_name }}" }

      it "resolves faker expressions" do
        result = resolve_with({})
        expect(result).to match(/Name: \w+/)
      end
    end

    context "when a variable is undefined" do
      let(:input) { "Hello {{ missing_var }}!" }

      it "raises an error" do
        expect { resolve_with({}) }.to raise_error(SpecForge::Error::MissingVariableError) do |error|
          expect(error.message).to eq("Undefined variable \"missing_var\"")
        end
      end
    end

    context "when a variable resolves to an array" do
      let(:input) { "Users: {{ users }}" }

      it "converts array to string representation" do
        result = resolve_with(users: ["Alice", "Bob"])

        expect(result).to eq('Users: ["Alice","Bob"]')
      end
    end

    context "when a variable resolves to a hash" do
      let(:input) { "Config: {{ config }}" }

      it "converts hash to string" do
        result = resolve_with(config: {api_key: "secret"})

        expect(result).to match(/Config: \{"api_key":"secret"\}/)
      end
    end
  end

  describe "#resolved" do
    let(:input) { "Hello {{ name }}!" }

    it "caches the result" do
      result1 = resolve_with(name: "World")
      result2 = resolve_with(name: "World")

      expect(result1).to eq(result2)
    end
  end

  describe "type casting for single-template expressions" do
    context "when template resolves to an integer" do
      let(:input) { "{{ count }}" }

      it "returns an integer" do
        result = resolve_with(count: 42)
        expect(result).to eq(42)
        expect(result).to be_an(Integer)
      end
    end

    context "when template resolves to a float" do
      let(:input) { "{{ price }}" }

      it "returns a float" do
        result = resolve_with(price: 19.99)
        expect(result).to eq(19.99)
        expect(result).to be_a(Float)
      end
    end

    context "when template resolves to true" do
      let(:input) { "{{ flag }}" }

      it "returns true" do
        result = resolve_with(flag: true)
        expect(result).to eq(true)
      end
    end

    context "when template resolves to false" do
      let(:input) { "{{ flag }}" }

      it "returns false" do
        result = resolve_with(flag: false)
        expect(result).to eq(false)
      end
    end

    context "when template resolves to an array" do
      let(:input) { "{{ items }}" }

      it "returns an array" do
        result = resolve_with(items: [1, 2, 3])
        expect(result).to eq([1, 2, 3])
        expect(result).to be_an(Array)
      end
    end

    context "when template resolves to a hash" do
      let(:input) { "{{ config }}" }

      it "returns a hash" do
        result = resolve_with(config: {key: "value"})
        expect(result).to eq({key: "value"})
        expect(result).to be_a(Hash)
      end
    end

    context "when template contains a matcher expression" do
      let(:input) { "{{ kind_of.string }}" }

      it "preserves the matcher object without converting to string" do
        result = resolve_with({})

        # Verify the matcher is preserved, not converted to a string
        expect(result).to respond_to(:matches?)
        expect(result.matches?("hello")).to be true
        expect(result.matches?(123)).to be false
      end
    end

    context "when template with matcher expression is embedded in text" do
      let(:input) { "Retry-After: {{ kind_of.string }}" }

      it "converts matcher to string when embedded" do
        result = resolve_with({})

        # When embedded in a string, it gets converted to_s
        expect(result).to be_a(String)
        expect(result).to start_with("Retry-After: #<")
      end
    end
  end
end
