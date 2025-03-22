# frozen_string_literal: true

class PostsController < AuthorizedController
  skip_before_action :verify_token, only: [:index, :show]

  # GET /posts
  def index
    verify_token(allow_unauthorized: true)

    # Validate parameters
    allowed_sort_columns = ["created_at", "title", "updated_at"]
    return unless validate_sort_param(:sort, allowed_sort_columns)
    return unless validate_direction_param(:direction) # Add this line!
    return unless validate_boolean_param(:published)
    return unless validate_numeric_param(:limit)
    return unless validate_numeric_param(:offset)
    return unless validate_numeric_param(:user_id)

    # Start with all posts
    posts_scope = Post.all.includes(:user)

    # Apply filters
    # User filter
    posts_scope = posts_scope.where(user_id: params[:user_id]) if params[:user_id].present?

    # Title filter - if implemented
    posts_scope = posts_scope.where("title ILIKE ?", "%#{params[:title]}%") if params[:title].present?

    # Published filter
    if params[:published].present?
      published = ActiveModel::Type::Boolean.new.cast(params[:published])
      posts_scope = posts_scope.where(published: published)
    elsif current_user.nil? || current_user.role != "admin"
      # Default: non-admins see only published posts
      posts_scope = posts_scope.where(published: true)
    end

    # Get total count before pagination
    total_count = posts_scope.count

    # Apply sorting
    if params[:sort].present?
      direction = (params[:direction]&.downcase == "desc") ? :desc : :asc
      posts_scope = posts_scope.order(params[:sort] => direction)
    end

    # Apply pagination
    limit = params[:limit].present? ? params[:limit].to_i : 10
    offset = params[:offset].present? ? params[:offset].to_i : 0
    posts_scope = posts_scope.limit(limit).offset(offset)

    # Load and format the results
    render json: {
      total: total_count,
      posts: posts_scope.map { |post| post_to_json(post) }
    }
  end

  # GET /posts/:id
  def show
    verify_token(allow_unauthorized: true)

    post = find_post
    return if post.nil?

    # Then check permissions for private posts
    if !post.published && current_user.nil?
      return render_forbidden("You don't have access to this post")
    elsif !post.published && current_user.role != "admin" && post.user_id != current_user.id
      return render_forbidden("You don't have access to this post")
    end

    render json: {post: post_to_json(post)}
  end

  # POST /posts
  def create
    post = Post.new(post_params)
    post.user = current_user

    if post.save
      render json: {post: post_to_json(post)}, status: :created
    else
      render json: {errors: post.errors.full_messages}, status: :unprocessable_entity
    end
  end

  # PATCH /posts/:id
  def update
    post = find_post
    return if post.nil?

    # Only post author or admin can update
    if post.user_id != current_user.id && current_user.role != "admin"
      return render_forbidden("You cannot edit another user's post")
    end

    if post.update(post_params)
      render json: {post: post_to_json(post)}
    else
      render json: {errors: post.errors.full_messages}, status: :unprocessable_entity
    end
  end

  # DELETE /posts/:id
  def destroy
    post = find_post
    return if post.nil?

    # Only post author or admin can delete
    if post.user_id != current_user.id && current_user.role != "admin"
      return render_forbidden("You cannot delete another user's post")
    end

    post.destroy
    head :no_content
  end

  private

  def find_post
    post = Post.find_by(id: params[:id])
    render_not_found("Post not found") unless post

    post
  end

  def post_params
    params.require(:post).permit(:title, :content, :published)
  end

  def post_to_json(post)
    {
      id: post.id,
      title: post.title,
      content: post.content,
      published: post.published,
      user_id: post.user_id,
      author: post.user.name,
      created_at: post.created_at,
      updated_at: post.updated_at,
      comments_count: post.comments.count
    }
  end
end
