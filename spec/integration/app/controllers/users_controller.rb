# frozen_string_literal: true

class UsersController < ApplicationController
  # GET /users
  def index
    # Get the limit parameter with a default of all users
    limit = params[:limit].present? ? params[:limit].to_i : User.count

    # Get a limited set of users
    users = User.limit(limit)

    # Return with metadata
    render json: {
      total: User.count,
      users:
    }
  end

  # GET /users/:id
  def show
    user = User.find_by(id: params[:id])

    if user
      render json: {user: user}
    else
      # Return 404 for non-existent users
      render json: {error: "User not found"}, status: :not_found
    end
  end

  # POST /users
  def create
    # Better error reporting for validation failures
    user = User.new(user_params)

    if user.save
      render json: {user: user}, status: :created
    else
      render json: {errors: user.errors.full_messages}, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /users/:id
  def update
    user = User.find_by(id: params[:id])

    if user.nil?
      render json: {error: "User not found"}, status: :not_found
      return
    end

    # Extract user attributes, handling both nested and root params
    user_attributes = params[:user] || params
    if user.update(user_params(user_attributes))
      render json: {user: user}
    else
      render json: {errors: user.errors.full_messages}, status: :unprocessable_entity
    end
  end

  # DELETE /users/:id
  def destroy
    user = User.find_by(id: params[:id])

    if user
      user.destroy
      head :no_content
    else
      render json: {error: "User not found"}, status: :not_found
    end
  end

  private

  def user_params(parameters = params)
    parameters.permit(:name, :email, :role, :active, :password)
  end
end
