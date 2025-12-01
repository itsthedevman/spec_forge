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

  describe "#callback" do
    before do
      # Clean slate for each test
      SpecForge::Callbacks.instance.clear
    end

    context "when value is blank" do
      it "is expected to pass for nil" do
        expect { validator.callback(nil) }.not_to raise_error
      end

      it "is expected to pass for empty string" do
        expect { validator.callback("") }.not_to raise_error
      end

      it "is expected to pass for empty array" do
        expect { validator.callback([]) }.not_to raise_error
      end
    end

    context "when value is a string" do
      context "and callback is registered" do
        before do
          SpecForge::Callbacks.register("my_callback") {}
        end

        it "is expected to pass validation" do
          expect { validator.callback("my_callback") }.not_to raise_error
        end
      end

      context "and callback is not registered" do
        it "is expected to raise UndefinedCallbackError" do
          expect { validator.callback("unknown_callback") }
            .to raise_error(SpecForge::Error::UndefinedCallbackError)
        end

        it "is expected to include the callback name in the error" do
          expect { validator.callback("unknown_callback") }
            .to raise_error(SpecForge::Error::UndefinedCallbackError, /unknown_callback/)
        end

        it "is expected to include available callbacks in the error" do
          SpecForge::Callbacks.register("existing_one") {}
          SpecForge::Callbacks.register("another_one") {}

          expect { validator.callback("missing") }
            .to raise_error(SpecForge::Error::UndefinedCallbackError, /existing_one.*another_one/m)
        end
      end
    end

    context "when value is a hash" do
      context "and callback is registered" do
        before do
          SpecForge::Callbacks.register("my_callback") {}
        end

        it "is expected to pass validation when name key exists" do
          expect { validator.callback(name: "my_callback") }.not_to raise_error
        end

        it "is expected to pass validation with additional args" do
          hash = {name: "my_callback", args: {foo: "bar"}}
          expect { validator.callback(hash) }.not_to raise_error
        end
      end

      context "and callback is not registered" do
        it "is expected to raise UndefinedCallbackError" do
          expect { validator.callback({name: "unknown_callback"}) }
            .to raise_error(SpecForge::Error::UndefinedCallbackError)
        end

        it "is expected to pass the callback name to the error" do
          hash = {name: "unknown", args: [1, 2, 3]}

          expect { validator.callback(hash) }
            .to raise_error(
              SpecForge::Error::UndefinedCallbackError,
              /The callback "unknown" was referenced but hasn't been defined/
            )
        end
      end

      context "when hash is empty or missing name key" do
        it "is expected to return early for empty hash" do
          expect { validator.callback({}) }.not_to raise_error
        end

        it "is expected to return early when name key is missing" do
          expect { validator.callback({args: [1, 2, 3]}) }.not_to raise_error
        end
      end
    end
  end
end
