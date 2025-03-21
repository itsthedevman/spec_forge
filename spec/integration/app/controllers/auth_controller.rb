# frozen_string_literal: true

class AuthController < AuthorizedController
  skip_before_action :verify_token, only: [:login]

  # POST /auth/login
  def login
    user = User.find_by(email: params[:email])

    # Simple password check for demo purposes
    # In a real app, you'd use has_secure_password or similar
    if user&.authenticate(params[:password])
      # Create a new token for this session
      token = user.api_tokens.create!

      render json: {
        token: token.token,
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role
        }
      }
    else
      render json: {error: "Invalid email or password"}, status: :unauthorized
    end
  end

  # GET /auth/me
  def me
    render json: {
      user: {
        id: current_user.id,
        name: current_user.name,
        email: current_user.email,
        role: current_user.role
      }
    }
  end

  # POST /auth/logout
  def logout
    current_token.destroy

    render json: {
      message: "Successfully logged out"
    }
  end
end
