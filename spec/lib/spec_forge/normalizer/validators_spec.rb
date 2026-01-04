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
end
