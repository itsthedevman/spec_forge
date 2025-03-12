# frozen_string_literal: true

class StatusController < ApplicationController
  def index
    render json: {
      status: "ok",
      version: "1.0",
      server_time: Time.current,
      environment: Rails.env
    }
  end
end
