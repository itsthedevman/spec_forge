# frozen_string_literal: true

class AuthorizedController < ApplicationController
  before_action :verify_token

  attr_reader :current_token, :current_user

  private

  def verify_token
    authorization_header = request.headers[:Authorization]
    return render_forbidden if authorization_header.blank?

    token = authorization_header.delete_prefix("Bearer ")
    return render_forbidden if token.blank?

    api_token = ApiToken.eager_load(:user).find_by(token:)
    return render_forbidden if api_token.nil?

    @current_token = api_token
    @current_user = api_token.user
  end
end
