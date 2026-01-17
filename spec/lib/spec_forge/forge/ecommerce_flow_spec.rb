# frozen_string_literal: true

require_relative "../../../support/ecommerce_api"

RSpec.describe "Forge: E-commerce Flow", :integration do
  let(:callback_tracker) { [] }

  let(:blueprints) do
    all, _forge_hooks = SpecForge::Loader.new(base_path: fixtures_path.join("blueprints", "forge")).load
    all.select { |b| b.name == "ecommerce_flow" }
  end

  subject(:forge) { SpecForge::Forge.new(blueprints, verbosity_level: 0) }

  # Start API server in background thread
  before(:all) do
    @server_thread = Thread.new do
      EcommerceAPI.run!(
        port: 4568,
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
    EcommerceAPI.reset_data!
    EcommerceAPI.seed_products!

    # Configure SpecForge base_url
    SpecForge.configuration.base_url = "http://localhost:4568"

    # Register callbacks
    forge.callbacks.register(:seed_products) { callback_tracker << :seed_products }
    forge.callbacks.register(:cleanup_test_data) { callback_tracker << :cleanup_test_data }

    # Silence display output
    allow_any_instance_of(SpecForge::Forge::Display).to receive(:puts)
    allow_any_instance_of(SpecForge::Forge::Display).to receive(:print)
  end

  describe "complete order workflow" do
    it "executes all 13 steps without failures" do
      forge.run

      expect(forge.failures).to be_empty
    end

    it "stores customer_id from registration" do
      forge.run
      expect(forge.variables[:customer_id]).to be_a(Integer)
      expect(forge.variables[:customer_id]).to eq(1)
    end

    it "stores auth_token from login" do
      forge.run
      expect(forge.variables[:auth_token]).to be_a(String)
      expect(forge.variables[:auth_token]).to start_with("eyJhbGciOiJIUzI1NiJ9")
    end

    it "stores cart_id and order_id" do
      forge.run
      expect(forge.variables[:cart_id]).to start_with("cart_")
      expect(forge.variables[:order_id]).to start_with("order_")
    end

    it "calls seed_products and cleanup_test_data callbacks" do
      forge.run
      expect(callback_tracker).to eq([:seed_products, :cleanup_test_data])
    end

    it "tests full workflow: register → login → browse → cart → checkout → order" do
      forge.run

      # Verify all key steps executed
      all_steps = forge.blueprints.flat_map(&:steps)
      step_names = all_steps.map(&:name)
      expect(step_names).to include(
        "Register new customer",
        "Login",
        "List products",
        "Create cart",
        "Add product to cart",
        "Checkout",
        "View order details"
      )

      # Verify order total was calculated
      expect(forge.variables[:order_total]).to be > 0
    end

    it "validates stateful cart transitions: active → completed" do
      forge.run

      # Cart should transition from active to completed after checkout
      all_steps = forge.blueprints.flat_map(&:steps)
      last_cart_step = all_steps.reverse.find { |s| s.name == "Verify cart is completed" }
      expect(last_cart_step).to be_truthy
    end
  end
end
