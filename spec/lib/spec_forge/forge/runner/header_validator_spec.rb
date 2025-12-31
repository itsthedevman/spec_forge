# frozen_string_literal: true

RSpec.describe SpecForge::Forge::Runner::HeaderValidator do
  describe "#validate!" do
    let(:headers) {}
    let(:expected) {}

    subject(:validate!) { described_class.new(headers, expected).validate! }

    context "when all matchers succeed" do
      let(:headers) { {"Content-Type" => "application/json", "X-Request-Id" => "abc123"} }
      let(:expected) { {"Content-Type" => eq("application/json"), "X-Request-Id" => eq("abc123")} }

      it "is expected not to raise an error" do
        expect { validate! }.not_to raise_error
      end
    end

    context "when a matcher doesn't match" do
      let(:headers) { {"Content-Type" => "text/html"} }
      let(:expected) { {"Content-Type" => eq("application/json")} }

      it "is expected to raise a HeaderValidationFailure" do
        expect { validate! }
          .to raise_error(SpecForge::Error::HeaderValidationFailure) do |error|
            expect(error.failures.size).to eq(1)
            expect(error.failures.first[:header]).to eq("Content-Type")
            expect(error.failures.first[:message]).to include("expected: \"application/json\"")
            expect(error.failures.first[:message]).to include("got: \"text/html\"")
          end
      end
    end

    context "when a header is missing" do
      let(:headers) { {"Content-Type" => "application/json"} }
      let(:expected) { {"Content-Type" => eq("application/json"), "X-Request-Id" => eq("abc123")} }

      it "is expected to raise a HeaderValidationFailure" do
        expect { validate! }
          .to raise_error(SpecForge::Error::HeaderValidationFailure) do |error|
            expect(error.failures.size).to eq(1)
            expect(error.failures.first[:header]).to eq("X-Request-Id")
            expect(error.failures.first[:message]).to eq("header not found")
          end
      end
    end

    context "when using case-insensitive header matching" do
      let(:headers) { {"content-type" => "application/json"} }
      let(:expected) { {"Content-Type" => eq("application/json")} }

      it "is expected not to raise an error" do
        expect { validate! }.not_to raise_error
      end
    end

    context "when expected key is lowercase and actual is mixed case" do
      let(:headers) { {"Content-Type" => "application/json"} }
      let(:expected) { {"content-type" => eq("application/json")} }

      it "is expected not to raise an error" do
        expect { validate! }.not_to raise_error
      end
    end

    context "when there are multiple failures" do
      let(:headers) { {"Content-Type" => "text/html"} }
      let(:expected) do
        {
          "Content-Type" => eq("application/json"),
          "X-Request-Id" => eq("abc123")
        }
      end

      it "is expected to collect all failures" do
        expect { validate! }
          .to raise_error(SpecForge::Error::HeaderValidationFailure) do |error|
            expect(error.failures.size).to eq(2)

            headers_with_failures = error.failures.map { |f| f[:header] }
            expect(headers_with_failures).to contain_exactly("Content-Type", "X-Request-Id")
          end
      end
    end

    context "when using different matcher types" do
      context "when using include matcher" do
        let(:headers) { {"Content-Type" => "application/json; charset=utf-8"} }
        let(:expected) { {"Content-Type" => include("application/json")} }

        it "is expected not to raise an error" do
          expect { validate! }.not_to raise_error
        end
      end

      context "when using regex matcher" do
        let(:headers) { {"X-Request-Id" => "req-abc123-xyz"} }
        let(:expected) { {"X-Request-Id" => match(/^req-.*-xyz$/)} }

        it "is expected not to raise an error" do
          expect { validate! }.not_to raise_error
        end
      end

      context "when using start_with matcher" do
        let(:headers) { {"Content-Type" => "application/json"} }
        let(:expected) { {"Content-Type" => start_with("application/")} }

        it "is expected not to raise an error" do
          expect { validate! }.not_to raise_error
        end
      end
    end

    context "when handling edge cases" do
      context "when headers are empty and expected is empty" do
        let(:headers) { {} }
        let(:expected) { {} }

        it "is expected not to raise an error" do
          expect { validate! }.not_to raise_error
        end
      end

      context "when using symbol keys in expected" do
        let(:headers) { {"Content-Type" => "application/json"} }
        let(:expected) { {"Content-Type": eq("application/json")} }

        it "is expected not to raise an error" do
          expect { validate! }.not_to raise_error
        end
      end

      context "when header value is nil" do
        let(:headers) { {"X-Custom" => nil} }
        let(:expected) { {"X-Custom" => be_nil} }

        it "is expected not to raise an error" do
          expect { validate! }.not_to raise_error
        end
      end
    end
  end
end
