# frozen_string_literal: true

RSpec.describe SpecForge::Forge do
  let(:blueprints) do
    SpecForge::Loader.new(
      base_path: fixtures_path.join("blueprints", "forge")
    ).load
  end

  let(:mock_backend) { instance_double(SpecForge::HTTP::Backend, connection: double) }
  let(:callback_tracker) { [] }

  subject(:forge) { described_class.new(blueprints, verbosity_level: 0) }

  before do
    # Mock HTTP layer so we don't need a real API
    allow(SpecForge::HTTP::Backend).to receive(:new).and_return(mock_backend)

    # Setup callbacks with tracking
    forge.callbacks.register(:setup_test_data) do
      callback_tracker << :setup_test_data
    end

    forge.callbacks.register(:cleanup_test_data) do
      callback_tracker << :cleanup_test_data
    end

    forge.callbacks.register(:log_create_request) do
      callback_tracker << :log_create_request
    end

    forge.callbacks.register(:verify_user_created) do
      callback_tracker << :verify_user_created
    end

    forge.callbacks.register(:initialize_environment) do
      callback_tracker << :initialize_environment
    end
  end

  describe "integration: full lifecycle execution" do
    it "executes blueprints with callbacks, requests, and variable storage" do
      response = Struct.new(:status, :headers, :body, keyword_init: true)

      # Mock HTTP responses
      allow(mock_backend).to receive(:post).and_return(
        response.new(
          status: 201,
          headers: {"Content-Type" => "application/json"},
          body: {id: 42, name: "John Doe", email: "john@example.com"}
        )
      )

      allow(mock_backend).to receive(:get).and_return(
        response.new(
          status: 200,
          headers: {"Content-Type" => "application/json"},
          body: {id: 42, name: "John Doe", email: "john@example.com"}
        )
      )

      allow(mock_backend).to receive(:put).and_return(
        response.new(
          status: 200,
          headers: {"Content-Type" => "application/json"}
        )
      )

      allow(mock_backend).to receive(:delete).and_return(
        response.new(status: 204, headers: {}, body: {})
      )

      # Run the forge
      forge.run

      # Verify callbacks fired
      expect(callback_tracker).to include(:setup_test_data)
      expect(callback_tracker).to include(:cleanup_test_data)
      expect(callback_tracker).to include(:initialize_environment)

      # Verify variables were stored and accessible
      expect(forge.variables[:user_id]).to eq(42)
      expect(forge.variables[:created_email]).to eq("john@example.com")

      # Verify HTTP calls were made
      expect(mock_backend).to have_received(:post)
      expect(mock_backend).to have_received(:get)
      expect(mock_backend).to have_received(:put)
      expect(mock_backend).to have_received(:delete)
    end
  end
end
