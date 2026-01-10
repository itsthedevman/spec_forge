# frozen_string_literal: true

RSpec.describe SpecForge::Step do
  describe "#initialize" do
    describe "transform_source" do
      subject(:step) do
        described_class.new(
          name: "Test step",
          source: source_input
        )
      end

      context "when source is nil" do
        let(:source_input) { nil }

        it "returns nil" do
          expect(step.source).to be_nil
        end
      end

      context "when source is empty" do
        let(:source_input) { {} }

        it "returns nil" do
          expect(step.source).to be_nil
        end
      end

      context "when source has file_name and line_number" do
        let(:source_input) { {file_name: "blueprints/users.yml", line_number: 42} }

        it "creates a Source object" do
          expect(step.source).to be_a(SpecForge::Step::Source)
        end

        it "sets the file_name" do
          expect(step.source.file_name).to eq("blueprints/users.yml")
        end

        it "sets the line_number" do
          expect(step.source.line_number).to eq(42)
        end

        it "has a string representation" do
          expect(step.source.to_s).to eq("blueprints/users.yml:42")
        end
      end
    end

    describe "transform_source for included_by" do
      subject(:step) do
        described_class.new(
          name: "Test step",
          source: {file_name: "test.yml", line_number: 1},
          included_by: included_by_input
        )
      end

      context "when included_by is nil" do
        let(:included_by_input) { nil }

        it "returns nil" do
          expect(step.included_by).to be_nil
        end
      end

      context "when included_by has file_name and line_number" do
        let(:included_by_input) { {file_name: "shared/common.yml", line_number: 10} }

        it "creates a Source object" do
          expect(step.included_by).to be_a(SpecForge::Step::Source)
        end

        it "sets the file_name" do
          expect(step.included_by.file_name).to eq("shared/common.yml")
        end

        it "sets the line_number" do
          expect(step.included_by.line_number).to eq(10)
        end
      end
    end

    describe "transform_call" do
      subject(:step) do
        described_class.new(
          name: "Test step",
          source: {file_name: "test.yml", line_number: 1},
          call: call_input
        )
      end

      context "when call is nil" do
        let(:call_input) { nil }

        it "returns nil" do
          expect(step.call).to be_nil
        end

        it "returns false for call?" do
          expect(step.call?).to be false
        end
      end

      context "when call is empty" do
        let(:call_input) { {} }

        it "returns nil" do
          expect(step.call).to be_nil
        end
      end

      context "when call has name and arguments" do
        let(:call_input) { {name: "create_user", arguments: {role: "admin", active: true}} }

        it "creates a Call object" do
          expect(step.call).to be_a(SpecForge::Step::Call)
        end

        it "sets the callback_name" do
          expect(step.call.callback_name).to eq("create_user")
        end

        it "sets the arguments" do
          expect(step.call.arguments).to eq({role: "admin", active: true})
        end

        it "returns true for call?" do
          expect(step.call?).to be true
        end
      end

      context "when call has only name" do
        let(:call_input) { {name: "setup_database"} }

        it "creates a Call object" do
          expect(step.call).to be_a(SpecForge::Step::Call)
        end

        it "sets the callback_name" do
          expect(step.call.callback_name).to eq("setup_database")
        end

        it "has nil arguments" do
          expect(step.call.arguments).to be_nil
        end
      end
    end

    describe "transform_expect" do
      subject(:step) do
        described_class.new(
          name: "Test step",
          source: {file_name: "test.yml", line_number: 1},
          expect: expect_input
        )
      end

      context "when expect is nil" do
        let(:expect_input) { nil }

        it "returns nil" do
          expect(step.expect).to be_nil
        end

        it "returns false for expect?" do
          expect(step.expect?).to be false
        end
      end

      context "when expect is empty" do
        let(:expect_input) { [] }

        it "returns nil" do
          expect(step.expect).to be_nil
        end
      end

      context "when expect has a single expectation" do
        let(:expect_input) { [{status: 200}] }

        it "returns an array of Expect objects" do
          expect(step.expect).to be_an(Array)
          expect(step.expect.size).to eq(1)
          expect(step.expect.first).to be_a(SpecForge::Step::Expect)
        end

        it "returns true for expect?" do
          expect(step.expect?).to be true
        end

        it "sets the status as an Attribute" do
          expect(step.expect.first.status).to be_a(SpecForge::Attribute)
          expect(step.expect.first.status.resolved).to eq(200)
        end
      end

      context "when expect has multiple expectations" do
        let(:expect_input) do
          [
            {status: 200, json: {content: {id: 1}}},
            {status: 201, headers: {"content-type" => "application/json"}}
          ]
        end

        it "returns an array with multiple Expect objects" do
          expect(step.expect.size).to eq(2)
          expect(step.expect).to all(be_a(SpecForge::Step::Expect))
        end

        it "sets status on each expectation" do
          expect(step.expect[0].status.resolved).to eq(200)
          expect(step.expect[1].status.resolved).to eq(201)
        end
      end

      context "when expect has headers" do
        let(:expect_input) { [{headers: {"X-Custom-Header" => "value", "Content-Type" => "application/json"}}] }

        it "converts headers to Attributes" do
          headers = step.expect.first.headers
          expect(headers).to be_a(Hash)
          expect(headers.values).to all(be_a(SpecForge::Attribute))
        end
      end

      context "when expect has json content" do
        let(:expect_input) { [{json: {content: {name: "Test", items: [1, 2, 3]}}}] }

        it "stores json content as a ResolvableHash" do
          json = step.expect.first.json
          expect(json[:content]).to be_a(SpecForge::Attribute::ResolvableHash)
        end

        it "resolves json content correctly" do
          json = step.expect.first.json
          expect(json[:content].resolved).to eq({name: "Test", items: [1, 2, 3]})
        end
      end

      context "when expect has json size" do
        let(:expect_input) { [{json: {size: 5}}] }

        it "stores json size as an Attribute" do
          json = step.expect.first.json
          expect(json[:size]).to be_a(SpecForge::Attribute)
          expect(json[:size].resolved).to eq(5)
        end
      end

      context "when expect has json schema" do
        let(:expect_input) { [{json: {schema: {type: "object", properties: {id: {type: "integer"}}}}}] }

        it "stores json schema directly" do
          json = step.expect.first.json
          expect(json[:schema]).to eq({type: "object", properties: {id: {type: "integer"}}})
        end
      end

      context "when expect has raw body" do
        let(:expect_input) { [{raw: "plain text response"}] }

        it "stores raw as an Attribute" do
          expect(step.expect.first.raw).to be_a(SpecForge::Attribute)
          expect(step.expect.first.raw.resolved).to eq("plain text response")
        end
      end

      it "provides expects alias" do
        step = described_class.new(
          name: "Test step",
          source: {file_name: "test.yml", line_number: 1},
          expect: [{status: 200}]
        )
        expect(step.expects).to eq(step.expect)
      end
    end

    describe "transform_store" do
      subject(:step) do
        described_class.new(
          name: "Test step",
          source: {file_name: "test.yml", line_number: 1},
          store: store_input
        )
      end

      context "when store is nil" do
        let(:store_input) { nil }

        it "returns nil" do
          expect(step.store).to be_nil
        end

        it "returns false for store?" do
          expect(step.store?).to be false
        end
      end

      context "when store is empty" do
        let(:store_input) { {} }

        it "returns nil" do
          expect(step.store).to be_nil
        end
      end

      context "when store has simple values" do
        let(:store_input) { {user_id: 123, username: "testuser"} }

        it "converts values to Attributes" do
          expect(step.store).to be_a(Hash)
          expect(step.store[:user_id]).to be_a(SpecForge::Attribute)
          expect(step.store[:username]).to be_a(SpecForge::Attribute)
        end

        it "resolves to the original values" do
          expect(step.store[:user_id].resolved).to eq(123)
          expect(step.store[:username].resolved).to eq("testuser")
        end

        it "returns true for store?" do
          expect(step.store?).to be true
        end
      end

      context "when store has nested values" do
        let(:store_input) { {user: {id: 1, name: "Test"}} }

        it "converts nested hash to ResolvableHash" do
          expect(step.store[:user]).to be_a(SpecForge::Attribute::ResolvableHash)
        end

        it "resolves nested values" do
          expect(step.store[:user].resolved).to eq({id: 1, name: "Test"})
        end
      end

      context "when store has array values" do
        let(:store_input) { {ids: [1, 2, 3]} }

        it "converts array to ResolvableArray" do
          expect(step.store[:ids]).to be_a(SpecForge::Attribute::ResolvableArray)
        end

        it "resolves array values" do
          expect(step.store[:ids].resolved).to eq([1, 2, 3])
        end
      end
    end

    describe "transform_hooks" do
      subject(:step) do
        described_class.new(
          name: "Test step",
          source: {file_name: "test.yml", line_number: 1},
          hook: hook_input
        )
      end

      context "when hook is nil" do
        let(:hook_input) { nil }

        it "returns nil" do
          expect(step.hook).to be_nil
        end

        it "returns false for hook?" do
          expect(step.hook?).to be false
        end
      end

      context "when hook is empty" do
        let(:hook_input) { {} }

        it "returns nil" do
          expect(step.hook).to be_nil
        end
      end

      context "when hook has blank values" do
        let(:hook_input) { {before: nil, after: nil} }

        it "returns nil" do
          expect(step.hook).to be_nil
        end
      end

      context "when hook has a single before callback" do
        let(:hook_input) { {before: {name: "setup_data", arguments: {count: 5}}} }

        it "creates a hash with an array of Call objects" do
          expect(step.hook).to be_a(Hash)
          expect(step.hook[:before]).to be_an(Array)
          expect(step.hook[:before].first).to be_a(SpecForge::Step::Call)
        end

        it "sets the callback_name" do
          expect(step.hook[:before].first.callback_name).to eq("setup_data")
        end

        it "sets the arguments" do
          expect(step.hook[:before].first.arguments).to eq({count: 5})
        end

        it "returns true for hook?" do
          expect(step.hook?).to be true
        end
      end

      context "when hook has callbacks for multiple events" do
        let(:hook_input) do
          {
            before: {name: "setup", arguments: {}},
            after: {name: "cleanup", arguments: {force: true}}
          }
        end

        it "creates arrays of Call objects for each event" do
          expect(step.hook[:before]).to be_an(Array)
          expect(step.hook[:after]).to be_an(Array)
          expect(step.hook[:before].first).to be_a(SpecForge::Step::Call)
          expect(step.hook[:after].first).to be_a(SpecForge::Step::Call)
        end

        it "sets correct callback names" do
          expect(step.hook[:before].first.callback_name).to eq("setup")
          expect(step.hook[:after].first.callback_name).to eq("cleanup")
        end
      end

      context "when hook has multiple callbacks for the same event" do
        let(:hook_input) do
          {
            before: [
              {name: "setup_database", arguments: {reset: true}},
              {name: "seed_data", arguments: {count: 10}}
            ]
          }
        end

        it "creates an array with multiple Call objects" do
          expect(step.hook[:before]).to be_an(Array)
          expect(step.hook[:before].size).to eq(2)
          expect(step.hook[:before]).to all(be_a(SpecForge::Step::Call))
        end

        it "sets correct callback names for each" do
          expect(step.hook[:before][0].callback_name).to eq("setup_database")
          expect(step.hook[:before][1].callback_name).to eq("seed_data")
        end

        it "sets correct arguments for each" do
          expect(step.hook[:before][0].arguments).to eq({reset: true})
          expect(step.hook[:before][1].arguments).to eq({count: 10})
        end
      end

      context "when hook has mixed nil and valid values" do
        let(:hook_input) { {before: nil, after: {name: "cleanup"}} }

        it "only includes non-nil hooks" do
          expect(step.hook.keys).to eq([:after])
          expect(step.hook[:after]).to be_an(Array)
          expect(step.hook[:after].first).to be_a(SpecForge::Step::Call)
        end
      end

      it "provides hooks alias" do
        step = described_class.new(
          name: "Test step",
          source: {file_name: "test.yml", line_number: 1},
          hook: {before: {name: "setup"}}
        )
        expect(step.hooks).to eq(step.hook)
      end
    end

    describe "debug attribute" do
      subject(:step) do
        described_class.new(
          name: "Test step",
          source: {file_name: "test.yml", line_number: 1},
          debug: debug_input
        )
      end

      context "when debug is nil" do
        let(:debug_input) { nil }

        it "returns false" do
          expect(step.debug).to be false
        end

        it "returns false for debug?" do
          expect(step.debug?).to be false
        end
      end

      context "when debug is false" do
        let(:debug_input) { false }

        it "returns false" do
          expect(step.debug).to be false
        end
      end

      context "when debug is true" do
        let(:debug_input) { true }

        it "returns true" do
          expect(step.debug).to be true
        end

        it "returns true for debug?" do
          expect(step.debug?).to be true
        end
      end

      context "when debug is truthy but not true" do
        let(:debug_input) { "yes" }

        it "returns false (only accepts exactly true)" do
          expect(step.debug).to be false
        end
      end
    end

    describe "simple attributes" do
      subject(:step) do
        described_class.new(
          name: "Test step",
          source: {file_name: "test.yml", line_number: 1},
          description: description_input,
          documentation: documentation_input,
          tags: tags_input
        )
      end

      let(:description_input) { nil }
      let(:documentation_input) { nil }
      let(:tags_input) { nil }

      context "when description is nil" do
        it "returns nil" do
          expect(step.description).to be_nil
        end
      end

      context "when description is provided" do
        let(:description_input) { "This step creates a new user" }

        it "returns the description" do
          expect(step.description).to eq("This step creates a new user")
        end
      end

      context "when documentation is nil" do
        it "returns nil" do
          expect(step.documentation).to be_nil
        end
      end

      context "when documentation is provided" do
        let(:documentation_input) { {summary: "Creates user", details: "Full details here"} }

        it "returns the documentation hash" do
          expect(step.documentation).to eq({summary: "Creates user", details: "Full details here"})
        end
      end

      context "when tags is nil" do
        it "returns nil" do
          expect(step.tags).to be_nil
        end
      end

      context "when tags are provided" do
        let(:tags_input) { ["smoke", "api", "users"] }

        it "returns the tags array" do
          expect(step.tags).to eq(["smoke", "api", "users"])
        end
      end
    end

    describe "name attribute" do
      it "sets the name from input" do
        step = described_class.new(
          name: "Create user step",
          source: {file_name: "test.yml", line_number: 1}
        )
        expect(step.name).to eq("Create user step")
      end
    end

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

        it "sets content-type to application/json" do
          expect(step.request.headers.resolved["content-type"]).to eq("application/json")
        end
      end

      context "when raw is present" do
        let(:request_input) do
          {
            url: "/api/test",
            http_verb: "POST",
            headers: {"content-type" => "text/plain"},
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

      context "when json is present but content-type is already set" do
        let(:request_input) do
          {
            url: "/api/test",
            http_verb: "POST",
            headers: {"content-type" => "application/json; charset=utf-8"},
            json: {name: "Test"}
          }
        end

        it "preserves the existing content-type" do
          expect(step.request.headers.resolved["content-type"]).to eq("application/json; charset=utf-8")
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

        it "sets content-type to text/plain" do
          expect(step.request.headers.resolved["content-type"]).to eq("text/plain")
        end
      end

      context "when headers with content-type are present but json is not" do
        let(:request_input) do
          {
            url: "/api/test",
            http_verb: "POST",
            headers: {"content-type" => "text/xml"},
            raw: "<xml>test</xml>"
          }
        end

        it "preserves the existing content-type" do
          expect(step.request.headers.resolved["content-type"]).to eq("text/xml")
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
