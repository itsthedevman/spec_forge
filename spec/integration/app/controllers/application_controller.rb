class ApplicationController < ActionController::API
  include ApiResponses

  rescue_from ActiveRecord::RecordNotFound, with: :render_record_not_found
  rescue_from ActiveModel::ValidationError, with: :render_validation_errors
end
