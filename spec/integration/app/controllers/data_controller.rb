# frozen_string_literal: true

class DataController < ApplicationController
  def types
    render json: {
      string_value: "Hello, world!",
      number_value: 42,
      decimal_value: 3.14159,
      boolean_value: true,
      null_value: nil,
      date_value: Date.current.iso8601,
      array_simple: [1, 2, 3, 4, 5],
      array_objects: [
        {id: 1, name: "Item 1", tags: ["important", "featured"]},
        {id: 2, name: "Item 2", tags: ["draft"]},
        {id: 3, name: "Item 3", tags: ["archived", "featured"]}
      ],
      nested_object: {
        level1: {
          level2: {
            level3: "Deep value",
            items_count: 5,
            enabled: true
          }
        }
      }
    }
  end

  def users
    response.headers["X-Total-Count"] = "42"
    response.headers["X-Pagination-Pages"] = "3"
    response.headers["X-Pagination-Current"] = "1"

    render json: {
      total: User.count,
      active_count: User.where(active: true).count,
      users: User.limit(3).map do |user|
        {
          id: user.id,
          name: user.name,
          email: user.email,
          created_at: user.created_at.iso8601,
          role: user.role
        }
      end
    }
  end

  def headers
    # Return any client headers we received
    client_id = request.headers["X-Client-ID"]
    accept = request.headers["Accept"]

    # Set some response headers for testing
    response.headers["Content-Type"] = "application/json; charset=utf-8"
    response.headers["X-Request-ID"] = SecureRandom.uuid
    response.headers["X-API-Version"] = "1.0.3"
    response.headers["Cache-Control"] = "max-age=3600, private, must-revalidate"
    response.headers["Vary"] = "Accept, Origin"

    # Return success response
    render json: {
      success: true,
      headers_received: {
        client_id: client_id,
        accept: accept
      }
    }
  end
end
