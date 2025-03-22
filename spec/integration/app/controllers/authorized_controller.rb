# frozen_string_literal: true

class AuthorizedController < ApplicationController
  before_action :verify_token

  attr_reader :current_token, :current_user

  private

  def verify_token(allow_unauthorized: false)
    authorization_header = request.headers[:Authorization]

    if authorization_header.blank?
      return if allow_unauthorized
      return render_forbidden
    end

    token = authorization_header.delete_prefix("Bearer ")
    return render_forbidden if token.blank?

    api_token = ApiToken.eager_load(:user).find_by(token:)
    return render_forbidden if api_token.nil?

    @current_token = api_token
    @current_user = api_token.user
  end

  def require_admin
    return if current_user&.role == "admin"

    render json: {error: "Admin access required"}, status: :forbidden
  end
end
