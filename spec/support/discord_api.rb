# frozen_string_literal: true

require "sinatra/base"
require "json"

class DiscordAPI < Sinatra::Base
  set :show_exceptions, false
  set :raise_errors, true

  # In-memory data store
  def self.reset_data!
    @channels = {}
    @messages = {}
    @next_channel_id = 1000
    @next_message_id = 1000
  end

  reset_data!

  # Helpers
  helpers do
    def json_body
      body_content = request.body.read
      JSON.parse(body_content, symbolize_names: true)
    rescue JSON::ParserError => e
      halt 400, {error: "Invalid JSON: #{e.message}", body: body_content.inspect}.to_json
    end

    def authenticate!
      auth_header = request.env["HTTP_AUTHORIZATION"]
      unless auth_header&.start_with?("Bot ")
        status 401
        halt({message: "401: Unauthorized", code: 0}.to_json)
      end
    end

    def snowflake
      (Time.now.to_f * 1000).to_i.to_s
    end
  end

  before do
    content_type :json
  end

  # ============================================================
  # Guild Endpoints
  # ============================================================

  get "/api/v10/guilds/:id" do
    authenticate!

    {
      id: "81384788765712384",
      name: "Discord Developers",
      icon: "abc123",
      owner_id: "80351110224678912",
      permissions: "2147483647",
      features: ["COMMUNITY", "NEWS"],
      member_count: 50000,
      presence_count: 5000,
      channels: [
        {id: "399942396007890945", type: 0, name: "general"}
      ]
    }.to_json
  end

  get "/api/v10/guilds/:id/channels" do
    authenticate!

    [
      {
        id: "399942396007890945",
        type: 0,
        name: "general",
        position: 0,
        permission_overwrites: [],
        parent_id: nil,
        nsfw: false
      },
      {
        id: "399942396007890946",
        type: 0,
        name: "random",
        position: 1,
        permission_overwrites: [],
        parent_id: "399942396007890940",
        nsfw: false
      }
    ].to_json
  end

  post "/api/v10/guilds/:id/channels" do
    authenticate!
    data = json_body

    # Validation error
    if data[:name].to_s.empty?
      status 400
      return {
        message: "Invalid Form Body",
        code: 50035,
        errors: {
          name: {
            _errors: [{code: "BASE_TYPE_REQUIRED", message: "Required field"}]
          }
        }
      }.to_json
    end

    channels = self.class.instance_variable_get(:@channels)
    next_id = self.class.instance_variable_get(:@next_channel_id)

    channel_id = snowflake
    channel = {
      id: channel_id,
      type: data[:type] || 0,
      guild_id: params[:id],
      name: data[:name],
      topic: data[:topic],
      position: 10
    }

    channels[channel_id] = channel
    self.class.instance_variable_set(:@next_channel_id, next_id + 1)

    status 201
    channel.to_json
  end

  get "/api/v10/guilds/:id/members" do
    authenticate!

    [
      {
        user: {
          id: "80351110224678912",
          username: "Nelly",
          discriminator: "0",
          avatar: "abc123"
        },
        nick: nil,
        roles: ["admin", "moderator"],
        joined_at: "2015-04-26T06:26:56.936000+00:00",
        deaf: false,
        mute: false
      }
    ].to_json
  end

  delete "/api/v10/guilds/:id" do
    authenticate!

    status 403
    {message: "Missing Permissions", code: 50013}.to_json
  end

  # ============================================================
  # Channel Endpoints
  # ============================================================

  get "/api/v10/channels/:id" do
    authenticate!

    # Handle 404 for unknown channel
    if params[:id] == "000000000000000000"
      status 404
      return {message: "Unknown Channel", code: 10003}.to_json
    end

    {
      id: params[:id],
      type: 0,
      guild_id: "81384788765712384",
      name: "general",
      topic: "General discussion",
      nsfw: false,
      last_message_id: "123456789",
      rate_limit_per_user: 0
    }.to_json
  end

  patch "/api/v10/channels/:id" do
    authenticate!
    data = json_body

    channels = self.class.instance_variable_get(:@channels)
    channel = channels[params[:id]]

    if channel
      channel[:name] = data[:name] if data[:name]
      channel[:topic] = data[:topic] if data[:topic]
      channel.to_json
    else
      {
        id: params[:id],
        name: data[:name],
        topic: data[:topic]
      }.to_json
    end
  end

  delete "/api/v10/channels/:id" do
    authenticate!

    channels = self.class.instance_variable_get(:@channels)
    channel = channels.delete(params[:id])

    if channel
      channel.to_json
    else
      {
        id: params[:id],
        type: 0,
        name: "renamed-channel"
      }.to_json
    end
  end

  # ============================================================
  # Message Endpoints
  # ============================================================

  get "/api/v10/channels/:channel_id/messages" do
    authenticate!

    [
      {
        id: "123456789",
        channel_id: params[:channel_id],
        author: {
          id: "80351110224678912",
          username: "Nelly"
        },
        content: "Hello, world!",
        timestamp: "2024-01-15T10:30:00.000000+00:00",
        edited_timestamp: nil,
        mentions: [],
        attachments: [],
        embeds: []
      }
    ].to_json
  end

  post "/api/v10/channels/:channel_id/messages" do
    authenticate!
    data = json_body

    messages = self.class.instance_variable_get(:@messages)
    message_id = snowflake

    message = {
      id: message_id,
      channel_id: params[:channel_id],
      content: data[:content],
      embeds: data[:embeds] || [],
      author: {
        id: "123456789012345678",
        username: "TestBot"
      }
    }

    messages[message_id] = message
    message.to_json
  end

  patch "/api/v10/channels/:channel_id/messages/:message_id" do
    authenticate!
    data = json_body

    messages = self.class.instance_variable_get(:@messages)
    message = messages[params[:message_id]]

    if message
      message[:content] = data[:content] if data[:content]
      message.to_json
    else
      {
        id: params[:message_id],
        content: data[:content]
      }.to_json
    end
  end

  delete "/api/v10/channels/:channel_id/messages/:message_id" do
    authenticate!

    messages = self.class.instance_variable_get(:@messages)
    messages.delete(params[:message_id])

    status 204
    ""
  end

  # ============================================================
  # User Endpoints
  # ============================================================

  get "/api/v10/users/@me" do
    authenticate!

    {
      id: "123456789012345678",
      username: "TestBot",
      discriminator: "0",
      avatar: nil,
      bot: true,
      email: nil,
      verified: true,
      flags: 0
    }.to_json
  end

  get "/api/v10/users/:id" do
    authenticate!

    {
      id: params[:id],
      username: "Nelly",
      discriminator: "0",
      avatar: "abc123",
      banner: nil,
      accent_color: 16711680
    }.to_json
  end

  get "/api/v10/users/@me/guilds" do
    authenticate!

    [
      {
        id: "81384788765712384",
        name: "Discord Developers",
        icon: "abc123",
        owner: false,
        permissions: "2147483647"
      }
    ].to_json
  end

  # ============================================================
  # Error Endpoints
  # ============================================================

  get "/api/v10/gateway" do
    authenticate!

    # Simulate rate limit
    status 429
    headers["Retry-After"] = "5000"
    headers["X-RateLimit-Global"] = "false"

    {
      message: "You are being rate limited.",
      retry_after: 5.0,
      global: false
    }.to_json
  end
end
