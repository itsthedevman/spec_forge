class ApplicationController < ActionController::API
  include ApiResponses

  before_action :validate_content_type

  rescue_from ActiveRecord::RecordNotFound, with: :render_record_not_found
  rescue_from ActiveModel::ValidationError, with: :render_validation_errors

  def validate_content_type
    # Skip for GET, DELETE and OPTIONS requests
    return if request.get? || request.delete? || request.options?

    # Skip if content-type not specified (will use default)
    return if request.content_type.nil?

    # Check if content type is JSON or form
    valid_types = ["application/json", "application/x-www-form-urlencoded"]

    unless valid_types.include?(request.content_type.to_s.split(";").first.downcase)
      render json: {error: "Unsupported media type. Please use JSON."},
        status: :unsupported_media_type

      return false  # Ensure we stop execution after rendering
    end

    true
  end

  def validate_numeric_param(param_name)
    return true unless params[param_name].present?

    if !params[param_name].to_s.match?(/\A\d+\z/)
      render_bad_request("#{param_name.to_s.humanize} must be a number")
      return false
    end

    true
  end

  def validate_sort_param(param_name, allowed_columns)
    return true unless params[param_name].present?

    if !allowed_columns.include?(params[param_name].to_s)
      render_bad_request("Invalid sort column. Allowed values are: #{allowed_columns.join(", ")}")
      return false
    end

    true
  end

  def validate_boolean_param(param_name)
    return true unless params[param_name].present?

    value = params[param_name].to_s.downcase
    valid_values = ["true", "false", "1", "0", "yes", "no"]

    unless valid_values.include?(value)
      render_bad_request("#{param_name.to_s.humanize} must be a boolean value")
      return false
    end

    true
  end

  def validate_direction_param(param_name)
    return true unless params[param_name].present?

    valid_directions = ["asc", "desc"]
    unless valid_directions.include?(params[param_name].to_s.downcase)
      render_bad_request("#{param_name.to_s.humanize} must be one of: #{valid_directions.join(", ")}")
      return false
    end

    true
  end
end
