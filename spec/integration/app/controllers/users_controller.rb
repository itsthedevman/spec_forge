# frozen_string_literal: true

class UsersController < AuthorizedController
  def index
    users = authorize User.all
    render json: {users:}
  end

  def show
    user = authorize User.find_by(id: params[:id])
    render json: {user:}
  end

  def create
    create_params = permit_create_params

    user = authorize User.new(**create_params)
    user.save!

    render json: {user:}
  end

  def update
    update_params = permit_update_params

    user = authorize User.find_by(id: params[:id])
    user.update!(update_params)

    render json: {user:}
  end

  def destroy
    user = authorize User.find_by(id: params[:id])
    user.destroy!

    render json: {user:}
  end

  private

  def permit_create_params
    params.permit(:name, :email, :role, :active)
  end

  def permit_update_params
    permit_create_params
  end
end
