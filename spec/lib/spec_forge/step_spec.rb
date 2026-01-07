# frozen_string_literal: true

RSpec.describe SpecForge::Step do
  describe "#initialize" do
    describe "transform_request" do
      subject(:step) do
        described_class.new(
          name: "Test step",
          source: {file_name: "test.yml", line_number: 1},
          request: request_input
        )
      end

      context "when request input is nil" do
        let(:request_input) { nil }

        it "returns nil" do
          expect(step.request).to be_nil
        end
      end

      context "when request input is empty" do
        let(:request_input) { {} }

        it "returns nil" do
          expect(step.request).to be_nil
        end
      end

      context "when base_url is present" do
        let(:request_input) do
          {
            base_url: "http://example.com",
            url: "/test"
          }
        end

        it "wraps base_url in an Attribute" do
          expect(step.request.base_url).to be_a(SpecForge::Attribute)
          expect(step.request.base_url.resolved).to eq("http://example.com")
        end
      end

      context "when url is present" do
        let(:request_input) do
          {
            url: "/api/users"
          }
        end

        it "wraps url in an Attribute" do
          expect(step.request.url).to be_a(SpecForge::Attribute)
          expect(step.request.url.resolved).to eq("/api/users")
        end
      end

      context "when http_verb is present" do
        let(:request_input) do
          {
            url: "/test",
            http_verb: "POST"
          }
        end

        it "sets the http_verb" do
          expect(step.request.http_verb.to_s).to eq("POST")
        end
      end

      context "when query is present" do
        let(:request_input) do
          {
            url: "/test",
            query: {page: 1, limit: 10}
          }
        end

        it "converts query values to Attributes" do
          expect(step.request.query[:page]).to be_a(SpecForge::Attribute)
          expect(step.request.query[:limit]).to be_a(SpecForge::Attribute)
        end

        it "resolves to the original values" do
          resolved = step.request.query.transform_values(&:resolved)
          expect(resolved).to eq({page: 1, limit: 10})
        end
      end

      context "when json is present" do
        let(:request_input) do
          {
            url: "/api/test",
            http_verb: "POST",
            json: {name: "Test"}
          }
        end

        it "converts json body values to Attributes" do
          expect(step.request.body[:name]).to be_a(SpecForge::Attribute)
        end

        it "resolves to the original json values" do
          resolved = step.request.body.transform_values(&:resolved)
          expect(resolved).to eq({name: "Test"})
        end

        it "sets Content-Type to application/json" do
          expect(step.request.headers.resolved["Content-Type"]).to eq("application/json")
        end
      end

      context "when raw is present" do
        let(:request_input) do
          {
            url: "/api/test",
            http_verb: "POST",
            headers: {"Content-Type" => "text/plain"},
            raw: "raw body content"
          }
        end

        it "wraps raw as body in an Attribute" do
          expect(step.request.body).to be_a(SpecForge::Attribute)
          expect(step.request.body.resolved).to eq("raw body content")
        end
      end

      context "when both json and raw are present" do
        let(:request_input) do
          {
            url: "/api/test",
            http_verb: "POST",
            json: {name: "Test"},
            raw: "raw body content"
          }
        end

        it "prefers json over raw" do
          resolved = step.request.body.transform_values(&:resolved)
          expect(resolved).to eq({name: "Test"})
        end
      end

      context "when json is present but Content-Type is already set" do
        let(:request_input) do
          {
            url: "/api/test",
            http_verb: "POST",
            headers: {"Content-Type" => "application/json; charset=utf-8"},
            json: {name: "Test"}
          }
        end

        it "preserves the existing Content-Type" do
          expect(step.request.headers.resolved["Content-Type"]).to eq("application/json; charset=utf-8")
        end
      end

      context "when headers are present but json is not" do
        let(:request_input) do
          {
            url: "/api/test",
            http_verb: "POST",
            headers: {"Authorization" => "Bearer token"},
            raw: "some data"
          }
        end

        it "sets Content-Type to text/plain" do
          expect(step.request.headers.resolved["Content-Type"]).to eq("text/plain")
        end
      end

      context "when headers with Content-Type are present but json is not" do
        let(:request_input) do
          {
            url: "/api/test",
            http_verb: "POST",
            headers: {"Content-Type" => "text/xml"},
            raw: "<xml>test</xml>"
          }
        end

        it "preserves the existing Content-Type" do
          expect(step.request.headers.resolved["Content-Type"]).to eq("text/xml")
        end
      end

      context "when neither json nor headers are present" do
        let(:request_input) do
          {
            url: "/api/test",
            http_verb: "GET"
          }
        end

        it "does not set headers" do
          expect(step.request.headers).to eq({})
        end
      end

      context "when json is nil but headers are empty" do
        let(:request_input) do
          {
            url: "/api/test",
            http_verb: "GET",
            headers: {}
          }
        end

        it "does not set headers" do
          expect(step.request.headers).to eq({})
        end
      end
    end
  end
end
