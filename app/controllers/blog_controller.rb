class BlogController < ApplicationController
  def index
    @posts = Post.active.recent
  end

  def show
    @post = Post.active.find_by(external_id: params[:id]) || Post.active.find_by(id: params[:id])
    raise ActiveRecord::RecordNotFound unless @post

    @md_body = MarkdownRenderer.call(@post.body) if @post.body.present?
  end
end
