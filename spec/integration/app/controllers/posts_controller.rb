# frozen_string_literal: true

class PostsController < AuthorizedController
  skip_before_action :verify_token, only: [:index, :show]
  before_action :set_post, only: [:show, :update, :destroy]

  # GET /posts
  def index
    # Handle filtering
    posts = if params[:user_id].present?
      Post.where(user_id: params[:user_id])
    else
      Post.all
    end

    # Handle published filter
    posts = posts.where(published: true) if current_user.nil? || current_user.role != "admin"

    # Handle pagination (simple version)
    limit = params[:limit].present? ? params[:limit].to_i : 10
    offset = params[:offset].present? ? params[:offset].to_i : 0
    posts = posts.limit(limit).offset(offset)

    render json: {
      total: posts.count,
      posts: posts.map { |post| post_to_json(post) }
    }
  end

  # GET /posts/:id
  def show
    # Check if post exists first
    return render_not_found("Post not found") unless @post

    # Then check permissions for private posts
    if !@post.published && current_user.nil?
      return render_forbidden("You don't have access to this post")
    elsif !@post.published && current_user.role != "admin" && @post.user_id != current_user.id
      return render_forbidden("You don't have access to this post")
    end

    render json: {post: post_to_json(@post)}
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
    # Only post author or admin can update
    if @post.user_id != current_user.id && current_user.role != "admin"
      return render_forbidden("You cannot edit another user's post")
    end

    if @post.update(post_params)
      render json: {post: post_to_json(@post)}
    else
      render json: {errors: @post.errors.full_messages}, status: :unprocessable_entity
    end
  end

  # DELETE /posts/:id
  def destroy
    # Only post author or admin can delete
    if @post.user_id != current_user.id && current_user.role != "admin"
      return render_forbidden("You cannot delete another user's post")
    end

    @post.destroy
    head :no_content
  end

  private

  def set_post
    @post = Post.find_by(id: params[:id])
    render_not_found("Post not found") unless @post
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
