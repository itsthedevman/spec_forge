# frozen_string_literal: true

RSpec.describe SpecForge::Forge do
  let(:mock_backend) { instance_double(SpecForge::HTTP::Backend, connection: double) }
  let(:callback_tracker) { [] }
  let(:response_struct) { Struct.new(:status, :headers, :body, keyword_init: true) }

  def load_blueprints
    SpecForge::Loader.new(
      base_path: fixtures_path.join("blueprints", "forge")
    ).load
  end

  def create_forge(blueprint_name)
    all_blueprints = load_blueprints
    blueprints = all_blueprints.select { |b| b.name == blueprint_name }
    described_class.new(blueprints, verbosity_level: 0)
  end

  before do
    allow(SpecForge::HTTP::Backend).to receive(:new).and_return(mock_backend)
    allow_any_instance_of(SpecForge::Forge::Display).to receive(:puts)
    allow_any_instance_of(SpecForge::Forge::Display).to receive(:print)
  end

  describe "simple_lifecycle" do
    subject(:forge) { create_forge("simple_lifecycle") }

    before do
      forge.callbacks.register(:setup_test_data) { callback_tracker << :setup_test_data }
      forge.callbacks.register(:cleanup_test_data) { callback_tracker << :cleanup_test_data }
      forge.callbacks.register(:initialize_environment) { callback_tracker << :initialize_environment }
    end

    it "executes full CRUD lifecycle with callbacks and variable storage" do
      allow(mock_backend).to receive(:post).and_return(
        response_struct.new(
          status: 201,
          headers: {"Content-Type" => "application/json"},
          body: {id: 42, name: "Test User", email: "test@example.com"}
        )
      )

      allow(mock_backend).to receive(:get).and_return(
        response_struct.new(
          status: 200,
          headers: {"Content-Type" => "application/json"},
          body: {id: 42, name: "Test User", email: "test@example.com"}
        )
      )

      allow(mock_backend).to receive(:put).and_return(
        response_struct.new(
          status: 200,
          headers: {"Content-Type" => "application/json"},
          body: {}
        )
      )

      allow(mock_backend).to receive(:delete).and_return(
        response_struct.new(status: 204, headers: {}, body: {})
      )

      forge.run

      expect(callback_tracker).to include(:setup_test_data, :cleanup_test_data, :initialize_environment)
      expect(forge.variables[:user_id]).to eq(42)
      expect(forge.variables[:created_email]).to eq("test@example.com")
      expect(mock_backend).to have_received(:post)
      expect(mock_backend).to have_received(:get)
      expect(mock_backend).to have_received(:put)
      expect(mock_backend).to have_received(:delete)
    end
  end

  describe "callbacks_with_args" do
    subject(:forge) { create_forge("callbacks_with_args") }

    before do
      forge.callbacks.register(:setup_data) { callback_tracker << :setup_data }
      forge.callbacks.register(:cleanup_data) { callback_tracker << :cleanup_data }
      forge.callbacks.register(:log_event) { |_ctx, event_type:, details:| callback_tracker << {log_event: {event_type:, details:}} }
      forge.callbacks.register(:process_items) { |_ctx, *items| callback_tracker << {process_items: items} }
    end

    it "executes callbacks with keyword arguments" do
      forge.run

      expect(callback_tracker).to include(:setup_data)
      expect(callback_tracker).to include(:cleanup_data)
      expect(callback_tracker).to include({log_event: {event_type: "test_start", details: "Starting callback test"}})
    end

    it "executes callbacks with positional arguments" do
      forge.run

      expect(callback_tracker).to include({process_items: ["item_one", "item_two", "item_three"]})
    end
  end

  describe "variable_interpolation" do
    subject(:forge) { create_forge("variable_interpolation") }

    it "interpolates variables in URLs and request bodies" do
      allow(mock_backend).to receive(:post).and_return(
        response_struct.new(status: 200, headers: {}, body: {})
      )

      allow(mock_backend).to receive(:put).and_return(
        response_struct.new(
          status: 200,
          headers: {},
          body: {id: 42, name: "Alice Smith"}
        )
      )

      forge.run

      expect(mock_backend).to have_received(:post) do |**kwargs|
        expect(kwargs[:url]).to eq("api/v1/users/42")
        expect(kwargs[:body]).to include("Alice")
      end

      expect(mock_backend).to have_received(:put) do |**kwargs|
        expect(kwargs[:url]).to eq("api/v1/users/42")
        expect(kwargs[:body]).to include("Alice Smith")
      end
    end

    it "stores response values for later use" do
      allow(mock_backend).to receive(:post).and_return(
        response_struct.new(status: 200, headers: {}, body: {})
      )

      allow(mock_backend).to receive(:put).and_return(
        response_struct.new(
          status: 200,
          headers: {},
          body: {id: 99, name: "Final Name"}
        )
      )

      forge.run

      expect(forge.variables[:response_id]).to eq(99)
      expect(forge.variables[:response_name]).to eq("Final Name")
    end
  end

  describe "nested_json_shape" do
    subject(:forge) { create_forge("nested_json_shape") }

    it "validates nested object structures with shape" do
      allow(mock_backend).to receive(:post).and_return(
        response_struct.new(
          status: 201,
          headers: {"Content-Type" => "application/json"},
          body: {
            id: 1,
            name: "Test Resource",
            config: {
              enabled: true,
              tags: ["alpha", "beta"]
            },
            metadata: {
              created_at: "2024-01-01T00:00:00Z",
              updated_at: nil
            }
          }
        )
      )

      expect { forge.run }.not_to raise_error
    end

    it "fails when nested structure doesn't match" do
      allow(mock_backend).to receive(:post).and_return(
        response_struct.new(
          status: 201,
          headers: {"Content-Type" => "application/json"},
          body: {
            id: "not-an-integer",
            name: "Test Resource",
            config: {
              enabled: true,
              tags: ["alpha", "beta"]
            },
            metadata: {
              created_at: "2024-01-01T00:00:00Z",
              updated_at: nil
            }
          }
        )
      )

      forge.run

      expect(forge.failures).not_to be_empty
    end
  end

  describe "array_response" do
    subject(:forge) { create_forge("array_response") }

    it "validates array responses with size and shape" do
      allow(mock_backend).to receive(:get).and_return(
        response_struct.new(
          status: 200,
          headers: {"Content-Type" => "application/json"},
          body: [
            {id: 1, name: "Item 1", active: true},
            {id: 2, name: "Item 2", active: false},
            {id: 3, name: "Item 3", active: true}
          ]
        )
      )

      expect { forge.run }.not_to raise_error
      expect(forge.failures).to be_empty
    end

    it "fails when array size doesn't match" do
      allow(mock_backend).to receive(:get).and_return(
        response_struct.new(
          status: 200,
          headers: {"Content-Type" => "application/json"},
          body: [
            {id: 1, name: "Item 1", active: true},
            {id: 2, name: "Item 2", active: false}
          ]
        )
      )

      forge.run

      expect(forge.failures).not_to be_empty
    end
  end

  describe "multiple_expectations" do
    subject(:forge) { create_forge("multiple_expectations") }

    it "validates all separate expectation blocks" do
      allow(mock_backend).to receive(:post).and_return(
        response_struct.new(
          status: 201,
          headers: {"Content-Type" => "application/json"},
          body: {
            id: 1,
            name: "Test User",
            email: "test@example.com"
          }
        )
      )

      forge.run

      expect(forge.failures).to be_empty
    end

    it "reports failures from any expectation block" do
      allow(mock_backend).to receive(:post).and_return(
        response_struct.new(
          status: 201,
          headers: {"Content-Type" => "application/json"},
          body: {
            id: 1,
            name: "Wrong Name",
            email: "test@example.com"
          }
        )
      )

      forge.run

      expect(forge.failures).not_to be_empty
    end
  end

  describe "headers_and_query" do
    subject(:forge) { create_forge("headers_and_query") }

    it "sends requests with interpolated headers and query params" do
      allow(mock_backend).to receive(:get).and_return(
        response_struct.new(
          status: 200,
          headers: {"Content-Type" => "application/json"},
          body: []
        )
      )

      forge.run

      expect(mock_backend).to have_received(:get) do |**kwargs|
        expect(kwargs[:headers][:Authorization]).to eq("Bearer secret_token_123")
        expect(kwargs[:headers][:"X-Custom-Header"]).to eq("custom-value")
        expect(kwargs[:query][:page]).to eq(2)
        expect(kwargs[:query][:limit]).to eq(25)
        expect(kwargs[:query][:sort]).to eq("created_at")
      end
    end
  end

  describe "error_responses" do
    subject(:forge) { create_forge("error_responses") }

    it "validates various error response codes and structures" do
      call_count = 0

      allow(mock_backend).to receive(:get) do
        call_count += 1
        case call_count
        when 1
          response_struct.new(
            status: 404,
            headers: {"Content-Type" => "application/json"},
            body: {error: "not_found", message: "User not found"}
          )
        when 2
          response_struct.new(
            status: 401,
            headers: {"Content-Type" => "application/json"},
            body: {error: "unauthorized"}
          )
        end
      end

      allow(mock_backend).to receive(:post).and_return(
        response_struct.new(
          status: 422,
          headers: {"Content-Type" => "application/json"},
          body: {errors: {name: ["can't be blank"]}}
        )
      )

      forge.run

      expect(forge.failures).to be_empty
    end
  end
end
