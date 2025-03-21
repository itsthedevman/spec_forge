# spec/integration/app/controllers/comments_controller.rb
class CommentsController < AuthorizedController
  skip_before_action :verify_token, only: [:index]

  # GET /posts/:post_id/comments
  def index
    post = find_post
    return if post.nil?

    comments = post.comments.includes(:user)

    # Simple pagination
    limit = params[:limit].present? ? params[:limit].to_i : 20
    offset = params[:offset].present? ? params[:offset].to_i : 0

    render json: {
      total: comments.count,
      comments: comments.limit(limit).offset(offset).map { |comment| comment_to_json(comment) }
    }
  end

  # POST /posts/:post_id/comments
  def create
    post = find_post
    return if post.nil?

    comment = post.comments.new(comment_params)
    comment.user = current_user

    if comment.save
      render json: {comment: comment_to_json(comment)}, status: :created
    else
      render json: {errors: comment.errors.full_messages}, status: :unprocessable_entity
    end
  end

  # PATCH /comments/:id
  def update
    comment = find_comment
    return if comment.nil?

    # Only comment author or admin can update
    if comment.user_id != current_user.id && current_user.role != "admin"
      return render_forbidden("You cannot edit another user's comment")
    end

    if comment.update(comment_params)
      render json: {comment: comment_to_json(comment)}
    else
      render json: {errors: @comment.errors.full_messages}, status: :unprocessable_entity
    end
  end

  # DELETE /comments/:id
  def destroy
    comment = find_comment
    return if comment.nil?

    # Only comment author, post author, or admin can delete
    if comment.user_id != current_user.id &&
        comment.post.user_id != current_user.id &&
        current_user.role != "admin"
      return render_forbidden("You don't have permission to delete this comment")
    end

    comment.destroy
    head :no_content
  end

  private

  def find_comment
    comment = Comment.find_by(id: params[:id])
    render_not_found("Comment not found") unless comment

    comment
  end

  def find_post
    post = Post.find_by(id: params[:post_id])
    render_not_found("Post not found") unless post

    post
  end

  def comment_params
    params.require(:comment).permit(:content)
  end

  def comment_to_json(comment)
    {
      id: comment.id,
      content: comment.content,
      post_id: comment.post_id,
      user_id: comment.user_id,
      author: comment.user.name,
      created_at: comment.created_at,
      updated_at: comment.updated_at
    }
  end
end
