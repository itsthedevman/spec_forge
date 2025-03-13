# app/controllers/users_controller.rb
class UsersController < ApplicationController
  # GET /users
  def index
    users = User.all
    render json: {users: users}
  end

  # GET /users/:id
  def show
    user = User.find_by(id: params[:id])

    if user
      render json: {user: user}
    else
      render json: {error: "User not found"}, status: :not_found
    end
  end

  # POST /users
  def create
    # Extract user attributes, handling both nested and root params
    user_attributes = params[:user] || params
    user = User.new(user_params(user_attributes))

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
    else
      # Extract user attributes, handling both nested and root params
      user_attributes = params[:user] || params
      if user.update(user_params(user_attributes))
        render json: {user: user}
      else
        render json: {errors: user.errors.full_messages}, status: :unprocessable_entity
      end
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

  def user_params(parameters)
    parameters.permit(:name, :email, :role, :active)
  end
end
