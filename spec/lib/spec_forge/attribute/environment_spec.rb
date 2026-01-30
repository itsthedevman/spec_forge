# frozen_string_literal: true

RSpec.describe SpecForge::Attribute::Environment do
  let(:input) {}

  subject(:attribute) { described_class.new(input) }

  include_examples "from_input_to_attribute" do
    let(:input) { "env.MY_VAR" }
  end

  describe "KEYWORD_REGEX" do
    subject(:regex) { described_class::KEYWORD_REGEX }

    it "matches 'env.' prefix" do
      expect("env.MY_VAR").to match(regex)
    end

    it "matches case insensitively" do
      expect("ENV.MY_VAR").to match(regex)
      expect("Env.my_var").to match(regex)
      expect("eNv.Something").to match(regex)
    end

    it "does not match without the prefix" do
      expect("MY_VAR").not_to match(regex)
      expect("environment.MY_VAR").not_to match(regex)
      expect("envMY_VAR").not_to match(regex)
    end
  end

  describe "#initialize" do
    let(:input) { "env.MY_VARIABLE" }

    it "strips the env. prefix from the variable name" do
      expect(attribute.instance_variable_get(:@variable_name)).to eq("MY_VARIABLE")
    end

    context "when input has mixed case prefix" do
      let(:input) { "ENV.MY_VARIABLE" }

      it "strips the prefix case insensitively" do
        expect(attribute.instance_variable_get(:@variable_name)).to eq("MY_VARIABLE")
      end
    end
  end

  describe "#value" do
    subject(:value) { attribute.value }

    context "when the environment variable exists" do
      let(:input) { "env.TEST_SPEC_FORGE_VAR" }
      let(:env_value) { "test_value_#{SecureRandom.hex(4)}" }

      around do |example|
        ENV["TEST_SPEC_FORGE_VAR"] = env_value
        example.run
      ensure
        ENV.delete("TEST_SPEC_FORGE_VAR")
      end

      it "returns the environment variable value" do
        expect(value).to eq(env_value)
      end
    end

    context "when the environment variable does not exist" do
      let(:input) { "env.NONEXISTENT_SPEC_FORGE_VAR_#{SecureRandom.hex(8)}" }

      it "returns nil" do
        expect(value).to be_nil
      end
    end

    context "when the environment variable is empty" do
      let(:input) { "env.EMPTY_SPEC_FORGE_VAR" }

      around do |example|
        ENV["EMPTY_SPEC_FORGE_VAR"] = ""
        example.run
      ensure
        ENV.delete("EMPTY_SPEC_FORGE_VAR")
      end

      it "returns an empty string" do
        expect(value).to eq("")
      end
    end

    context "when the variable name contains special characters" do
      let(:input) { "env.MY_VAR_123" }
      let(:env_value) { "special_value" }

      around do |example|
        ENV["MY_VAR_123"] = env_value
        example.run
      ensure
        ENV.delete("MY_VAR_123")
      end

      it "returns the correct value" do
        expect(value).to eq(env_value)
      end
    end
  end

  describe "Template integration" do
    let(:template) { SpecForge::Attribute::Template.new(input) }

    context "when used inside a template" do
      let(:input) { "{{ env.TEMPLATE_TEST_VAR }}" }
      let(:env_value) { "template_value_#{SecureRandom.hex(4)}" }

      around do |example|
        ENV["TEMPLATE_TEST_VAR"] = env_value
        example.run
      ensure
        ENV.delete("TEMPLATE_TEST_VAR")
      end

      it "creates an Environment attribute" do
        templates = template.instance_variable_get(:@templates)
        expect(templates.values.first).to be_a(described_class)
      end

      it "resolves to the environment variable value" do
        expect(template.value).to eq(env_value)
      end
    end

    context "when embedded in a string" do
      let(:input) { "API Key: {{ env.EMBEDDED_TEST_VAR }}" }
      let(:env_value) { "secret_key_123" }

      around do |example|
        ENV["EMBEDDED_TEST_VAR"] = env_value
        example.run
      ensure
        ENV.delete("EMBEDDED_TEST_VAR")
      end

      it "interpolates the environment variable value" do
        expect(template.value).to eq("API Key: secret_key_123")
      end
    end

    context "when mixed with other template expressions" do
      let(:input) { "{{ env.MIX_TEST_VAR }}/users/{{ user_id }}" }
      let(:env_value) { "https://api.example.com" }

      around do |example|
        ENV["MIX_TEST_VAR"] = env_value
        example.run
      ensure
        ENV.delete("MIX_TEST_VAR")
      end

      it "resolves environment variables alongside other attributes" do
        context = SpecForge::Forge::Context.new(
          variables: SpecForge::Forge::Variables.new(static: {user_id: 42})
        )

        result = SpecForge::Forge.with_context(context) do
          template.value
        end

        expect(result).to eq("https://api.example.com/users/42")
      end
    end
  end
end
