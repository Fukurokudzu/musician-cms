class Admin::PostsController < ApplicationController
  include AdminAuthorization

  before_action :set_post, only: [:edit, :update, :destroy]

  def index
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.update('admin_body', partial: 'index') }
      format.html { redirect_to admin_path }
    end
  end

  def new
    @post = Post.new
    render turbo_stream: turbo_stream.update('admin_body', partial: 'form', locals: { post: @post })
  end

  def create
    @post = Post.new(post_params)
    if @post.save
      AuditLogger.log(action: 'blog.created', target: @post, request: request,
                      metadata: { title: @post.title })
      flash.now[:success] = t('admin.posts.flash.created')
      render_index
    else
      flash.now[:error] = @post.errors.full_messages.join(', ')
      render turbo_stream: [
        turbo_stream.update('admin_body', partial: 'form', locals: { post: @post }),
        turbo_stream.update('flash', partial: 'layouts/flash')
      ], status: :unprocessable_entity
    end
  end

  def edit
    render turbo_stream: turbo_stream.update('admin_body', partial: 'form', locals: { post: @post })
  end

  def update
    if @post.update(post_params)
      AuditLogger.log(action: 'blog.updated', target: @post, request: request,
                      metadata: { title: @post.title, changes: post_params.keys })
      flash.now[:success] = t('admin.posts.flash.updated')
      render_index
    else
      flash.now[:error] = @post.errors.full_messages.join(', ')
      render turbo_stream: [
        turbo_stream.update('admin_body', partial: 'form', locals: { post: @post }),
        turbo_stream.update('flash', partial: 'layouts/flash')
      ], status: :unprocessable_entity
    end
  end

  def destroy
    if @post.update(soft_deleted: true)
      AuditLogger.log(action: 'blog.deleted', target: @post, request: request,
                      metadata: { title: @post.title })
      flash.now[:success] = t('admin.posts.flash.deleted')
    else
      flash.now[:error] = @post.errors.full_messages.join(', ')
    end
    render_index
  end

  private

  def set_post
    @post = Post.find_by(external_id: params[:id]) || Post.find_by(id: params[:id])
    raise ActiveRecord::RecordNotFound unless @post
  end

  def render_index
    render turbo_stream: [
      turbo_stream.update('admin_body', partial: 'index'),
      turbo_stream.update('flash', partial: 'layouts/flash')
    ]
  end

  def post_params
    params.require(:post).permit(:title, :body)
  end
end
