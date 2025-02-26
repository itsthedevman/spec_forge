# frozen_string_literal: true

module ApiResponses
  extend ActiveSupport::Concern

  private

  def render_not_found(message = "Resource not found")
    render json: {error: message}, status: :not_found
  end

  def render_forbidden(message = "You are not authorized to perform this action")
    render json: {error: message}, status: :forbidden
  end

  def render_unauthorized(message = "Authentication required")
    render json: {error: message}, status: :unauthorized
  end

  def render_unprocessable_entity(errors)
    render json: {errors: errors}, status: :unprocessable_entity
  end

  def render_bad_request(message = "Bad request")
    render json: {error: message}, status: :bad_request
  end

  # Handle ActiveRecord not found
  def render_record_not_found(exception)
    render_not_found(exception.message)
  end

  # Useful for model validations
  def render_validation_errors(record)
    render_unprocessable_entity(record.errors.full_messages)
  end
end
