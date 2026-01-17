# frozen_string_literal: true

require_relative "../../../support/discord_api"

RSpec.describe "Forge: Discord API", :integration do
  let(:blueprints) do
    all, _forge_hooks = SpecForge::Loader.new(base_path: fixtures_path.join("blueprints", "forge")).load
    all.select { |b| b.name == "discord_api" }
  end

  subject(:forge) { SpecForge::Forge.new(blueprints, verbosity_level: 0) }

  # Start API server in background thread
  before(:all) do
    @server_thread = Thread.new do
      DiscordAPI.run!(
        port: 4569,
        server: "webrick",
        logging: false,
        traps: false,
        server_settings: {
          Logger: WEBrick::Log.new(File::NULL),
          AccessLog: []
        }
      )
    end
  end

  after(:all) do
    @server_thread&.kill
  end

  before do
    # Reset data between tests
    DiscordAPI.reset_data!

    # Configure SpecForge base_url
    SpecForge.configuration.base_url = "http://localhost:4569"

    # Silence display output
    allow_any_instance_of(SpecForge::Forge::Display).to receive(:puts)
    allow_any_instance_of(SpecForge::Forge::Display).to receive(:print)
  end

  describe "Discord API endpoint validation" do
    it "validates all Discord API endpoints without failures" do
      forge.run

      expect(forge.failures).to be_empty
    end

    it "stores created channel ID for subsequent operations" do
      forge.run
      expect(forge.variables[:created_channel_id]).to be_a(String)
      expect(forge.variables[:created_channel_id]).to match(/^\d+$/)
    end

    it "stores message ID for edit and delete operations" do
      forge.run
      expect(forge.variables[:message_id]).to be_a(String)
      expect(forge.variables[:message_id]).to match(/^\d+$/)
    end

    describe "endpoint coverage" do
      it "tests guild endpoints (get, list channels, create channel, list members)" do
        forge.run

        all_steps = forge.blueprints.flat_map(&:steps)
        guild_steps = all_steps.select { |s| s.tags&.include?("guilds") }
        expect(guild_steps.count).to be >= 3

        step_names = guild_steps.map(&:name)
        expect(step_names).to include("Get Guild", "Get Guild Channels", "Create Guild Channel")
      end

      it "tests channel endpoints (get, modify, delete)" do
        forge.run

        all_steps = forge.blueprints.flat_map(&:steps)
        channel_steps = all_steps.select { |s| s.tags&.include?("channels") }
        expect(channel_steps.count).to be >= 3
      end

      it "tests message endpoints (list, create, edit, delete)" do
        forge.run

        all_steps = forge.blueprints.flat_map(&:steps)
        message_steps = all_steps.select { |s| s.tags&.include?("messages") }
        expect(message_steps.count).to be >= 4
      end

      it "tests user endpoints (get current user, get user, list guilds)" do
        forge.run

        all_steps = forge.blueprints.flat_map(&:steps)
        user_steps = all_steps.select { |s| s.tags&.include?("users") }
        expect(user_steps.count).to be >= 3
      end
    end

    describe "error response handling" do
      it "validates 401 unauthorized response" do
        forge.run

        all_steps = forge.blueprints.flat_map(&:steps)
        auth_error_step = all_steps.find { |s| s.name == "Unauthorized - No Token" }
        expect(auth_error_step).to be_truthy
      end

      it "validates 403 forbidden response" do
        forge.run

        all_steps = forge.blueprints.flat_map(&:steps)
        forbidden_step = all_steps.find { |s| s.name == "Forbidden - Missing Permissions" }
        expect(forbidden_step).to be_truthy
      end

      it "validates 404 not found response" do
        forge.run

        all_steps = forge.blueprints.flat_map(&:steps)
        not_found_step = all_steps.find { |s| s.name == "Not Found - Unknown Resource" }
        expect(not_found_step).to be_truthy
      end

      it "validates 429 rate limit response" do
        forge.run

        all_steps = forge.blueprints.flat_map(&:steps)
        rate_limit_step = all_steps.find { |s| s.name == "Rate Limited" }
        expect(rate_limit_step).to be_truthy
      end

      it "validates 400 validation error response" do
        forge.run

        all_steps = forge.blueprints.flat_map(&:steps)
        validation_step = all_steps.find { |s| s.name == "Validation Error - Invalid Channel Name" }
        expect(validation_step).to be_truthy
      end
    end

    describe "HTTP method coverage" do
      it "tests all CRUD operations (GET, POST, PATCH, DELETE)" do
        forge.run

        # Verify different HTTP methods were used
        all_steps = forge.blueprints.flat_map(&:steps)
        methods = all_steps.map { |s| s.request&.http_verb&.to_s }.compact.uniq
        expect(methods).to include("GET", "POST", "PATCH", "DELETE")
      end
    end

    describe "stateful operations" do
      it "creates channel and uses its ID in subsequent requests" do
        forge.run

        all_steps = forge.blueprints.flat_map(&:steps)
        create_step = all_steps.find { |s| s.name == "Create Guild Channel" }
        modify_step = all_steps.find { |s| s.name == "Modify Channel" }
        delete_step = all_steps.find { |s| s.name == "Delete Channel" }

        expect(create_step).to be_truthy
        expect(modify_step).to be_truthy
        expect(delete_step).to be_truthy
      end

      it "creates message and uses its ID for editing" do
        forge.run

        all_steps = forge.blueprints.flat_map(&:steps)
        create_msg_step = all_steps.find { |s| s.name == "Create Message" }
        edit_msg_step = all_steps.find { |s| s.name == "Edit Message" }

        expect(create_msg_step).to be_truthy
        expect(edit_msg_step).to be_truthy
      end
    end
  end
end
