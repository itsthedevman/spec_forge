# frozen_string_literal: true

require "sinatra/base"
require "json"

class EcommerceAPI < Sinatra::Base
  set :show_exceptions, false
  set :raise_errors, true

  # In-memory data store
  def self.reset_data!
    @customers = []
    @products = []
    @carts = {}
    @cart_items = {}
    @orders = {}
    @addresses = {}
    @next_customer_id = 1
    @next_cart_id = 1
    @next_order_id = 1
    @next_item_id = 1
    @next_address_id = 1
  end

  # Seed products for testing
  def self.seed_products!
    @products = [
      {
        id: 42,
        name: "Wireless Headphones",
        description: "High-quality wireless headphones with noise cancellation",
        price_cents: 9999,
        currency: "USD",
        in_stock: true,
        inventory_count: 50,
        category: "electronics",
        images: [
          {url: "https://example.com/headphones.jpg", alt: "Wireless Headphones"}
        ]
      },
      {
        id: 43,
        name: "USB-C Cable",
        description: "Durable USB-C to USB-C cable, 6ft length",
        price_cents: 1299,
        currency: "USD",
        in_stock: true,
        inventory_count: 200,
        category: "electronics",
        images: [
          {url: "https://example.com/cable.jpg", alt: nil}
        ]
      }
    ]
  end

  reset_data!
  seed_products!

  # Helpers
  helpers do
    def json_body
      body_content = request.body.read

      if body_content.empty?
        halt 400, {error: "Empty body"}.to_json
      end

      JSON.parse(body_content, symbolize_names: true)
    rescue JSON::ParserError => e
      halt 400, {error: "Invalid JSON: #{e.message}", body: body_content}.to_json
    end

    def authenticate!
      auth_header = request.env["HTTP_AUTHORIZATION"]
      halt 401, {error: "Unauthorized"}.to_json unless auth_header&.start_with?("Bearer ")

      token = auth_header.sub("Bearer ", "")
      halt 401, {error: "Invalid token"}.to_json if token.empty?
    end

    def find_customer(id)
      customer = self.class.instance_variable_get(:@customers).find { |c| c[:id] == id.to_i }
      halt 404, {error: "Customer not found"}.to_json unless customer
      customer
    end

    def find_product(id)
      product = self.class.instance_variable_get(:@products).find { |p| p[:id] == id.to_i }
      halt 404, {error: "Product not found"}.to_json unless product
      product
    end

    def find_cart(id)
      carts = self.class.instance_variable_get(:@carts)
      cart = carts[id]
      halt 404, {error: "Cart not found"}.to_json unless cart
      cart
    end

    def find_order(id)
      orders = self.class.instance_variable_get(:@orders)
      order = orders[id]
      halt 404, {error: "Order not found"}.to_json unless order
      order
    end
  end

  # POST /api/v1/customers - Register new customer
  post "/api/v1/customers" do
    content_type :json
    data = json_body

    customers = self.class.instance_variable_get(:@customers)
    next_id = self.class.instance_variable_get(:@next_customer_id)

    # Check if email already exists
    if customers.any? { |c| c[:email] == data[:email] }
      status 422
      return {error: "Email already exists"}.to_json
    end

    customer = {
      id: next_id,
      email: data[:email],
      password: data[:password], # In real app, would hash this
      name: data[:name],
      created_at: Time.now.utc.iso8601
    }

    customers << customer
    self.class.instance_variable_set(:@next_customer_id, next_id + 1)

    status 201
    customer.slice(:id, :email, :name, :created_at).to_json
  end

  # POST /api/v1/auth/login - Login
  post "/api/v1/auth/login" do
    content_type :json
    data = json_body

    customers = self.class.instance_variable_get(:@customers)
    customer = customers.find { |c| c[:email] == data[:email] && c[:password] == data[:password] }

    if customer
      token = "eyJhbGciOiJIUzI1NiJ9.#{customer[:id]}.test_signature"
      {
        token: token,
        expires_at: (Time.now + 86400).utc.iso8601,
        customer: customer.slice(:id, :email)
      }.to_json
    else
      status 401
      {error: "Invalid credentials"}.to_json
    end
  end

  # GET /api/v1/products - List products
  get "/api/v1/products" do
    authenticate!
    content_type :json

    products = self.class.instance_variable_get(:@products)

    # Filter by query params
    filtered = products
    filtered = filtered.select { |p| p[:category] == params[:category] } if params[:category]
    filtered = filtered.select { |p| p[:in_stock] == true } if params[:in_stock] == "true"

    filtered.map { |p| p.slice(:id, :name, :price_cents, :currency, :in_stock, :category) }.to_json
  end

  # GET /api/v1/products/:id - Get product details
  get "/api/v1/products/:id" do
    authenticate!
    content_type :json

    product = find_product(params[:id])
    product.to_json
  end

  # POST /api/v1/carts - Create cart
  post "/api/v1/carts" do
    authenticate!
    content_type :json

    # Extract customer_id from token (simplified)
    token = request.env["HTTP_AUTHORIZATION"].sub("Bearer ", "")
    customer_id = token.split(".")[1].to_i

    carts = self.class.instance_variable_get(:@carts)
    next_id = self.class.instance_variable_get(:@next_cart_id)

    cart_id = "cart_#{next_id}"
    cart = {
      id: cart_id,
      customer_id: customer_id,
      items: [],
      subtotal_cents: 0,
      status: "active"
    }

    carts[cart_id] = cart
    self.class.instance_variable_set(:@next_cart_id, next_id + 1)

    status 201
    cart.to_json
  end

  # POST /api/v1/carts/:id/items - Add item to cart
  post "/api/v1/carts/:id/items" do
    authenticate!
    content_type :json
    data = json_body

    cart = find_cart(params[:id])
    product = find_product(data[:product_id])

    cart_items = self.class.instance_variable_get(:@cart_items)
    next_id = self.class.instance_variable_get(:@next_item_id)

    item_id = "item_#{next_id}"
    quantity = data[:quantity]
    unit_price = product[:price_cents]

    item = {
      id: item_id,
      product_id: product[:id],
      quantity: quantity,
      unit_price_cents: unit_price,
      line_total_cents: unit_price * quantity
    }

    cart_items[item_id] = item
    cart[:items] << item
    cart[:subtotal_cents] = cart[:items].sum { |i| i[:line_total_cents] }

    self.class.instance_variable_set(:@next_item_id, next_id + 1)

    status 201
    item.to_json
  end

  # GET /api/v1/carts/:id - View cart
  get "/api/v1/carts/:id" do
    authenticate!
    content_type :json

    cart = find_cart(params[:id])
    cart.to_json
  end

  # PATCH /api/v1/carts/:cart_id/items/:item_id - Update cart item
  patch "/api/v1/carts/:cart_id/items/:item_id" do
    authenticate!
    content_type :json
    data = json_body

    cart = find_cart(params[:cart_id])
    item = cart[:items].find { |i| i[:id] == params[:item_id] }
    halt 404, {error: "Item not found"}.to_json unless item

    item[:quantity] = data[:quantity]
    item[:line_total_cents] = item[:unit_price_cents] * data[:quantity]
    cart[:subtotal_cents] = cart[:items].sum { |i| i[:line_total_cents] }

    item.to_json
  end

  # PUT /api/v1/carts/:id/shipping_address - Set shipping address
  put "/api/v1/carts/:id/shipping_address" do
    authenticate!
    content_type :json
    data = json_body

    cart = find_cart(params[:id])

    addresses = self.class.instance_variable_get(:@addresses)
    next_id = self.class.instance_variable_get(:@next_address_id)

    address = {
      id: next_id,
      street: data[:street],
      city: data[:city],
      state: data[:state],
      zip: data[:zip],
      country: data[:country]
    }

    addresses[cart[:id]] = address
    cart[:shipping_address] = address
    self.class.instance_variable_set(:@next_address_id, next_id + 1)

    address.to_json
  end

  # POST /api/v1/carts/:id/checkout - Checkout
  post "/api/v1/carts/:id/checkout" do
    authenticate!
    content_type :json
    json_body

    cart = find_cart(params[:id])
    halt 400, {error: "Cart is empty"}.to_json if cart[:items].empty?

    orders = self.class.instance_variable_get(:@orders)
    next_id = self.class.instance_variable_get(:@next_order_id)

    order_id = "order_#{next_id}"
    subtotal = cart[:subtotal_cents]
    tax = (subtotal * 0.08).to_i # 8% tax
    shipping = 500 # $5 flat rate

    order = {
      id: order_id,
      customer_id: cart[:customer_id],
      status: "confirmed",
      items: cart[:items].map { |i| i.slice(:product_id, :quantity, :unit_price_cents) },
      subtotal_cents: subtotal,
      tax_cents: tax,
      shipping_cents: shipping,
      total_cents: subtotal + tax + shipping,
      shipping_address: cart[:shipping_address],
      created_at: Time.now.utc.iso8601
    }

    orders[order_id] = order
    cart[:status] = "completed"
    self.class.instance_variable_set(:@next_order_id, next_id + 1)

    status 201
    order.to_json
  end

  # GET /api/v1/orders/:id - View order
  get "/api/v1/orders/:id" do
    authenticate!
    content_type :json

    order = find_order(params[:id])
    order.to_json
  end

  # GET /api/v1/customers/:id/orders - List customer orders
  get "/api/v1/customers/:id/orders" do
    authenticate!
    content_type :json

    customer_id = params[:id].to_i
    orders = self.class.instance_variable_get(:@orders)

    customer_orders = orders.values.select { |o| o[:customer_id] == customer_id }
    customer_orders.map { |o| o.slice(:id, :status, :total_cents, :created_at) }.to_json
  end
end
