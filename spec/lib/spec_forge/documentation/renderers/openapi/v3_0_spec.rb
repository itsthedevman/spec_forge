# frozen_string_literal: true

RSpec.describe SpecForge::Documentation::Renderers::OpenAPI::V3_0 do
  let(:input) { SpecForge::Documentation::Document.new(info:, endpoints:, structures:) }
  let(:info) { {} }
  let(:endpoints) { {} }
  let(:structures) { {} }
  let(:config) { SpecForge::Normalizer.default_documentation_config }

  subject(:output) { described_class.new(input).render }

  before do
    allow(SpecForge::Documentation).to receive(:config).and_return(config)
  end

  context "when the document is empty" do
    it "is expected to return the OAS 3.0 structure" do
      is_expected.to match(
        openapi: described_class::CURRENT_VERSION,
        info: {contact: {}, description: "", license: {}, title: "", version: ""},
        servers: [],
        tags: [],
        security: [],
        paths: {},
        components: {}
      )
    end
  end

  context "when the document has no endpoints" do
    it "is expected to show no paths" do
      is_expected.to include(paths: {})
    end
  end

  context "when the document is fully complete" do
    let(:info) do
      {
        title: "My API",
        version: "0.1.0",
        description: "This is my cool API",
        contact: {
          name: "Bryan",
          email: "bryan@itsthedevman.com"
        },
        license: {
          name: "MIT",
          url: "https://opensource.org/licenses/MIT"
        }
      }
    end

    let(:test_data) do
      data = {
        endpoints: [
          {
            spec_name: "create_user",
            expectation_name: "POST /users",
            base_url: "http://localhost:3000",
            url: "/users",
            http_verb: "POST",
            content_type: "application/json",
            request_body: {
              name: "Basic Test User",
              email: "gregorio@lockman-luettgen.test",
              password: "password12345"
            },
            request_headers: {},
            request_query: {},
            response_status: 201,
            response_body: {
              user: {
                id: Faker::Number.positive.to_i,
                name: "Basic Test User",
                email: "gregorio@lockman-luettgen.test",
                role: "user",
                password: "password12345",
                active: true,
                created_at: Time.current.to_s,
                updated_at: Time.current.to_s
              }
            },
            response_headers: {}
          },
          {
            spec_name: "get_user",
            expectation_name: "GET /users/{id}",
            base_url: "http://localhost:3000",
            url: "/users/{id}",
            http_verb: "GET",
            content_type: "application/json",
            request_body: {},
            request_headers: {},
            request_query: {
              id: 3535
            },
            response_status: 200,
            response_body: {
              user: {
                id: 3535,
                name: "Luise Ratke",
                email: "marine@harber-macgyver.example",
                role: "user",
                password: "password12345",
                active: true,
                created_at: Time.current.to_s,
                updated_at: Time.current.to_s
              }
            },
            response_headers: {}
          },
          {
            spec_name: "update_user",
            expectation_name: "PATCH /users/{id}",
            base_url: "http://localhost:3000",
            url: "/users/{id}",
            http_verb: "PATCH",
            content_type: "application/json",
            request_body: {
              name: "Updated Basic User"
            },
            request_headers: {},
            request_query: {
              id: 3536
            },
            response_status: 200,
            response_body: {
              user: {
                id: 3536,
                name: "Updated Basic User",
                email: "eliseo_kassulke@gleason.test",
                role: "user",
                password: "password12345",
                active: true,
                created_at: Time.current.to_s,
                updated_at: Time.current.to_s
              }
            },
            response_headers: {}
          }
        ],
        structures: []
      }

      SpecForge::Documentation::Builder.new(**data).prepare_endpoints
    end

    let(:endpoints) { test_data.endpoints }
    let(:structures) { test_data.structures }

    let(:config) do
      config = SpecForge::Normalizer.default_documentation_config
      config[:openapi] = {
        servers: [
          {
            url: Faker::Internet.url,
            description: Faker::String.random
          },
          {
            url: Faker::Internet.url,
            description: Faker::String.random
          }
        ],
        tags: {
          tag_1: Faker::String.random,
          tag_2: {
            description: Faker::String.random,
            external_docs: {
              url: Faker::Internet.url,
              description: Faker::String.random
            }
          }
        },
        security_schemes: {
          BasicHTTPScheme: {
            type: "http",
            scheme: "basic"
          },
          APIKeyScheme: {
            type: "apiKey",
            name: "api-key",
            in: "header"
          },
          JWTBearer: {
            type: "http",
            scheme: "bearer",
            bearer_format: "JWT"
          },
          OAuth: {
            type: "oauth2",
            flows: {
              implicit: {
                authorization_url: "https://example.com/api/oauth/dialog",
                scopes: {
                  "write:users": "modify users",
                  "read:users": "read users"
                }
              },
              authorization_code: {
                authorization_url: "https://example.com/api/oauth/dialog",
                token_url: "https://example.com/api/oauth/token",
                scopes: {
                  "write:users": "modify users",
                  "read:users": "read users"
                }
              }
            }
          }
        }
      }

      config
    end

    it "is expected to render a valid OAS 3.0 hash" do
      expect(output[:openapi]).to eq(described_class::CURRENT_VERSION)

      expect(output[:info]).to match(
        title: "My API",
        version: "0.1.0",
        description: "This is my cool API",
        contact: {name: "Bryan", email: "bryan@itsthedevman.com"},
        license: {name: "MIT", url: "https://opensource.org/licenses/MIT"}
      )

      expect(output[:servers]).to contain_exactly(
        {url: be_kind_of(String), description: be_kind_of(String)},
        {url: be_kind_of(String), description: be_kind_of(String)}
      )

      # expect(output[:tags]).to
      # expect(output[:security]).to
      # expect(output[:paths]).to
      # expect(output[:components]).to
    end
  end
end
