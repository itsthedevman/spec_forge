class ApplicationController < ActionController::API
  include Pundit::Authorization
  include ApiResponses

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from ActiveRecord::RecordNotFound, with: :render_record_not_found
  rescue_from ActiveModel::ValidationError, with: :render_validation_errors

  private

  def user_not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore

    status, message =
      if policy_name == "nil_class_policy"
        [404, "404 Not Found"]
      else
        [403, "403 Forbidden"]
      end

    render json: {status:, message:}, status: status
  end
end
