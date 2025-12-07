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
end
