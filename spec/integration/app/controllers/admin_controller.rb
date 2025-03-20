# app/controllers/admin_controller.rb
class AdminController < AuthorizedController
  # GET /admin/users
  def users
    users = User.all

    render json: {
      users: users.map do |user|
        {
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
          active: user.active,
          created_at: user.created_at
        }
      end
  }
  end
end
