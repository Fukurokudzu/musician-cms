class BlogController < ApplicationController
  def index
    @posts = Post.active.recent
  end

  def show
    @post = find_short_codeable!(public_scope: Post.active, param: params[:id])

    @md_body = MarkdownRenderer.call(@post.body) if @post.body.present?
  end
end
