# frozen_string_literal: true

RSpec.describe SpecForge::Error do
  describe SpecForge::Error::InvalidFakerClassError do
    let(:input) { "faker.nuumbre" }

    subject(:error) { described_class.new(input) }

    it "will provide them in the error" do
      expect(error.message).to match("Did you mean?")
    end
  end

  describe SpecForge::Error::InvalidFakerMethodError do
    let(:input) { "psoitive" }

    subject(:error) { described_class.new(input, Faker::Number) }

    it "will provide them in the error" do
      expect(error.message).to match("Did you mean?")
    end
  end

  describe SpecForge::Error::InvalidTypeError do
    let(:input) { nil }
    let(:expected_type) {}
    let(:for_thing) {}

    subject(:error) { described_class.new(input, expected_type, for: for_thing) }

    context "when the expected_type is a class" do
      let(:expected_type) { Hash }

      it do
        expect(error.message).to eq("Expected Hash, got NilClass")
      end
    end

    context "when the expected_type is an Array of classes" do
      let(:expected_type) { [String, Integer] }

      it do
        expect(error.message).to eq("Expected String or Integer, got NilClass")
      end

      context "and there are more than two classes" do
        let(:expected_type) { [String, Integer, Array] }

        it do
          expect(error.message).to eq("Expected String, Integer, or Array, got NilClass")
        end
      end
    end

    context "when 'for' is provided" do
      let(:expected_type) { String }
      let(:for_thing) { "'attribute'" }

      it do
        expect(error.message).to eq("Expected String, got NilClass for 'attribute'")
      end
    end
  end

  describe SpecForge::Error::MissingVariableError do
    subject(:error) { described_class.new(variable_name, available_variables:) }

    describe "error message formatting" do
      context "when no variables are available" do
        let(:variable_name) { "user_id" }
        let(:available_variables) { [] }

        it "is expected to show only the base message" do
          expect(error.message).to eq('Undefined variable "user_id"')
        end
      end

      context "when 1-5 variables are available with no close matches" do
        let(:variable_name) { "user_id" }
        let(:available_variables) { ["admin_email", "api_token", "session_key"] }

        it "is expected to show the available variables list" do
          expect(error.message).to eq(
            'Undefined variable "user_id".' \
            "\nAvailable: \"admin_email\", \"api_token\", \"session_key\""
          )
        end
      end

      context "when 1-5 variables are available with a close match" do
        let(:variable_name) { "user_idd" }
        let(:available_variables) { ["user_id", "admin_id", "post_id"] }

        it "is expected to show both the suggestion and available list" do
          expect(error.message).to match(/Undefined variable "user_idd"/)
          expect(error.message).to match(/Did you mean\?  user_id/)
          expect(error.message).to match(/Available: "user_id", "admin_id", "post_id"/)
        end
      end

      context "when more than 5 variables are available with a close match" do
        let(:variable_name) { "user_idd" }
        let(:available_variables) { ["user_id", "admin_id", "post_id", "comment_id", "session_id", "token_id"] }

        it "is expected to show only the suggestion" do
          expect(error.message).to match(/Undefined variable "user_idd"/)
          expect(error.message).to match(/Did you mean\?  user_id/)
          expect(error.message).not_to match(/Available:/)
        end
      end

      context "when more than 5 variables are available with no close match" do
        let(:variable_name) { "foobar" }
        let(:available_variables) { ["user_id", "admin_id", "post_id", "comment_id", "session_id", "token_id"] }

        it "is expected to show only the base message" do
          expect(error.message).to eq('Undefined variable "foobar"')
        end
      end

      context "when variable name is a symbol" do
        let(:variable_name) { :user_id }
        let(:available_variables) { ["admin_id", "post_id"] }

        it "is expected to convert it to string in the message" do
          expect(error.message).to match(/Undefined variable "user_id"/)
        end
      end

      context "with multiple close matches" do
        let(:variable_name) { "usr_id" }
        let(:available_variables) { ["user_id", "usr_name", "user_email"] }

        it "is expected to show all suggestions" do
          expect(error.message).to match(/Undefined variable "usr_id"/)
          expect(error.message).to match(/Did you mean\?/)
          # DidYouMean typically shows top matches
          expect(error.message).to match(/user_id/)
        end
      end

      context "when exactly 5 variables are available" do
        let(:variable_name) { "missing" }
        let(:available_variables) { ["var1", "var2", "var3", "var4", "var5"] }

        it "is expected to show the available list" do
          expect(error.message).to match(/Available: "var1", "var2", "var3", "var4", "var5"/)
        end
      end

      context "when exactly 6 variables are available" do
        let(:variable_name) { "missing" }
        let(:available_variables) { ["var1", "var2", "var3", "var4", "var5", "var6"] }

        it "is expected to not show the available list" do
          expect(error.message).not_to match(/Available:/)
        end
      end
    end
  end

  describe SpecForge::Error::InvalidBuildStrategy do
    subject(:error) { described_class.new("invalid_strategy") }

    it "includes the invalid strategy name" do
      expect(error.message).to include('"invalid_strategy"')
    end

    it "includes valid strategies" do
      expect(error.message).to include("Valid strategies include:")
    end
  end

  describe SpecForge::Error::InvalidStructureError do
    context "with SpecForge errors" do
      let(:errors) { [SpecForge::Error.new("test error")] }

      subject(:error) { described_class.new(errors) }

      it "includes the error message" do
        expect(error.message).to include("test error")
      end
    end

    context "with non-SpecForge errors" do
      let(:standard_error) do
        raise StandardError, "something went wrong"
      rescue => e
        e
      end
      let(:errors) { [standard_error] }

      subject(:error) { described_class.new(errors) }

      it "includes the error inspect output" do
        expect(error.message).to include("StandardError")
        expect(error.message).to include("something went wrong")
      end
    end
  end

  describe SpecForge::Error::LoadStepError do
    context "with a simple error" do
      let(:inner_error) { StandardError.new("inner problem") }
      let(:step) { {name: "test step", source: {file_name: "test.yml", line_number: 10}} }

      subject(:error) { described_class.new(inner_error, step) }

      it "includes the step name and source location" do
        expect(error.message).to include('Step: "test step" [test.yml:10]')
      end

      it "includes the cause" do
        expect(error.message).to include("Caused by:")
        expect(error.message).to include("inner problem")
      end
    end

    context "with a nested LoadStepError" do
      let(:inner_error) { StandardError.new("root cause") }
      let(:inner_step) { {name: "inner step", source: {file_name: "inner.yml", line_number: 5}} }
      let(:inner_load_error) { described_class.new(inner_error, inner_step) }
      let(:outer_step) { {name: "outer step", source: {file_name: "outer.yml", line_number: 15}} }

      subject(:error) { described_class.new(inner_load_error, outer_step) }

      it "includes both step names" do
        expect(error.message).to include('"outer step"')
        expect(error.message).to include('"inner step"')
      end
    end

    context "with a multi-line error message" do
      let(:inner_error) { StandardError.new("line one\nline two\nline three") }
      let(:step) { {name: "test step"} }

      subject(:error) { described_class.new(inner_error, step) }

      it "formats multi-line errors with indentation" do
        expect(error.message).to include("Caused by:")
        expect(error.message).to include("line one")
        expect(error.message).to include("line two")
      end
    end

    context "with unnamed step" do
      let(:inner_error) { StandardError.new("error") }
      let(:step) { {name: nil} }

      subject(:error) { described_class.new(inner_error, step) }

      it "shows unnamed placeholder" do
        expect(error.message).to include('"(unnamed)"')
      end
    end
  end

  describe SpecForge::Error::UndefinedCallbackError do
    context "with available callbacks" do
      subject(:error) { described_class.new(:missing_callback, [:setup, :teardown]) }

      it "includes the callback name" do
        expect(error.message).to include('"missing_callback"')
      end

      it "lists available callbacks" do
        expect(error.message).to include("Available callbacks are:")
        expect(error.message).to include('"setup"')
        expect(error.message).to include('"teardown"')
      end
    end

    context "without available callbacks" do
      subject(:error) { described_class.new(:missing_callback, []) }

      it "includes registration example" do
        expect(error.message).to include("SpecForge.register_callback(:missing_callback)")
      end
    end
  end

  describe SpecForge::Error::ExpectationFailure do
    let(:failed_examples) { ["example1", "example2", "example3"] }

    subject(:error) { described_class.new(failed_examples) }

    it "includes the count of failed examples" do
      expect(error.message).to eq("Failed expectations (3)")
    end

    it "stores the failed examples" do
      expect(error.failed_examples).to eq(failed_examples)
    end
  end
end
