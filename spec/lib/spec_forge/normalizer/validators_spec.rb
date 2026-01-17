RSpec.describe SpecForge::Normalizer::Validators do
  subject(:validator) { described_class.new("test spec") }

  describe "#present?" do
    it "is expected to pass when value is present" do
      expect { validator.present?("hello") }.not_to raise_error
      expect { validator.present?([1, 2, 3]) }.not_to raise_error
      expect { validator.present?(42) }.not_to raise_error
    end

    it "is expected to raise error when value is blank" do
      expect { validator.present?(nil) }
        .to raise_error(SpecForge::Error, /Value cannot be blank for test spec/)

      expect { validator.present?("") }
        .to raise_error(SpecForge::Error, /Value cannot be blank/)
    end

    it "is expected to include the label in error message" do
      validator = described_class.new("user email")
      expect { validator.present?(nil) }
        .to raise_error(SpecForge::Error, /user email/)
    end
  end

  describe "#http_verb" do
    it "is expected to pass for valid uppercase verbs" do
      %w[GET POST PUT PATCH DELETE].each do |verb|
        expect { validator.http_verb(verb) }.not_to raise_error
      end
    end

    it "is expected to pass for valid lowercase verbs" do
      %w[get post put patch delete].each do |verb|
        expect { validator.http_verb(verb) }.not_to raise_error
      end
    end

    it "is expected to pass for valid mixed-case verbs" do
      %w[Get PoSt PuT].each do |verb|
        expect { validator.http_verb(verb) }.not_to raise_error
      end
    end

    it "is expected to pass for valid verbs as symbols" do
      [:GET, :POST, :put, :delete].each do |verb|
        expect { validator.http_verb(verb) }.not_to raise_error
      end
    end

    it "is expected to pass for nil" do
      expect { validator.http_verb(nil) }.not_to raise_error
    end

    it "is expected to pass for empty string" do
      expect { validator.http_verb("") }.not_to raise_error
    end

    it "is expected to raise error for invalid verb" do
      expect { validator.http_verb("INVALID") }
        .to raise_error(SpecForge::Error, /Invalid HTTP verb/)
    end

    it "is expected to include the invalid verb in error message" do
      expect { validator.http_verb("NOPE") }
        .to raise_error(SpecForge::Error, /"NOPE"/)
    end

    it "is expected to include valid verbs in error message" do
      expect { validator.http_verb("BAD") }
        .to raise_error(SpecForge::Error, /Invalid HTTP verb "BAD" for test spec/)
    end

    it "is expected to include the label in error message" do
      validator = described_class.new("request method")
      expect { validator.http_verb("INVALID") }
        .to raise_error(SpecForge::Error, /request method/)
    end
  end

  describe "#json_expectation" do
    it "passes when only shape is defined" do
      expect { validator.json_expectation({shape: {id: "kind_of.integer"}}) }.not_to raise_error
    end

    it "passes when only schema is defined" do
      expect { validator.json_expectation({schema: {type: "object"}}) }.not_to raise_error
    end

    it "passes when neither is defined" do
      expect { validator.json_expectation({}) }.not_to raise_error
    end

    it "raises error when both shape and schema are defined" do
      expect {
        validator.json_expectation({shape: {id: "kind_of.integer"}, schema: {type: "object"}})
      }.to raise_error(SpecForge::Error, /Cannot define both "shape" and "schema"/)
    end
  end

  describe "#json_schema" do
    it "validates nested structure arrays" do
      schema = {
        type: "array",
        structure: [
          {type: "string"},
          {type: "integer"}
        ]
      }

      expect { validator.json_schema(schema) }.not_to raise_error
    end

    it "validates nested structure hashes" do
      schema = {
        type: "object",
        structure: {
          name: {type: "string"},
          age: {type: "integer"}
        }
      }

      expect { validator.json_schema(schema) }.not_to raise_error
    end
  end

  describe "#callback" do
    context "when the value is an array with a single hash" do
      it "passes when value has a valid name" do
        expect { validator.callback([{name: "my_callback"}]) }.not_to raise_error
      end

      it "passes when value has a name and hash arguments" do
        expect { validator.callback([{name: "my_callback", arguments: {id: 1}}]) }.not_to raise_error
      end

      it "passes when value has a name and array arguments" do
        expect { validator.callback([{name: "my_callback", arguments: [1, 2, 3]}]) }.not_to raise_error
      end

      it "passes when value has a name and empty arguments" do
        expect { validator.callback([{name: "my_callback", arguments: {}}]) }.not_to raise_error
        expect { validator.callback([{name: "my_callback", arguments: []}]) }.not_to raise_error
      end

      it "raises error when name is missing" do
        expect { validator.callback([{arguments: {id: 1}}]) }
          .to raise_error(SpecForge::Error)
      end

      it "raises error when name is wrong type" do
        expect { validator.callback([{name: 123}]) }
          .to raise_error(SpecForge::Error)
      end

      it "raises error when arguments is wrong type" do
        expect { validator.callback([{name: "my_callback", arguments: "invalid"}]) }
          .to raise_error(SpecForge::Error)
      end
    end

    context "when the value is an array of hashes" do
      it "passes when all callbacks are valid" do
        expect {
          validator.callback([
            {name: "first_callback"},
            {name: "second_callback", arguments: {id: 1}}
          ])
        }.not_to raise_error
      end

      it "passes when array has a single valid callback" do
        expect { validator.callback([{name: "my_callback"}]) }.not_to raise_error
      end

      it "passes when array is empty" do
        expect { validator.callback([]) }.not_to raise_error
      end

      it "raises error when any callback is missing name" do
        expect {
          validator.callback([
            {name: "valid_callback"},
            {arguments: {id: 1}}
          ])
        }.to raise_error(SpecForge::Error)
      end

      it "raises error when any callback has wrong type for name" do
        expect {
          validator.callback([
            {name: "valid_callback"},
            {name: 123}
          ])
        }.to raise_error(SpecForge::Error)
      end

      it "raises error when array contains nested arrays" do
        expect {
          validator.callback([
            {name: "valid_callback"},
            [{name: "nested_callback"}]
          ])
        }.to raise_error(SpecForge::Error)
      end

      it "raises error when array is deeply nested" do
        expect {
          validator.callback([[{name: "deeply_nested"}]])
        }.to raise_error(SpecForge::Error)
      end
    end
  end
end
