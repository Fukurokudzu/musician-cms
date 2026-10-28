class Admin::ReleasesController < ApplicationController
  before_action :set_release, only: [:show, :edit, :update]

  def index
    render turbo_stream: turbo_stream.update('admin_body', partial: 'system')
  end

  def show
    render turbo_stream: turbo_stream.update('admin_body', partial: 'show')
  end

  def edit
    render turbo_stream: turbo_stream.update('admin_body', partial: 'edit')
  end

  def update
    if @release.update(release_params)
      flash.now[:success] = 'Release updated'
      render turbo_stream: [
        turbo_stream.update('admin_body', partial: 'show'),
        turbo_stream.update('flash', partial: 'layouts/flash')
      ]
    else
      flash.now[:error] = @release.errors.full_messages.join(', ')
      render turbo_stream: turbo_stream.update('flash', partial: 'layouts/flash'), status: :unprocessable_entity
    end
  end

  private

  def set_release
    @release = Release.find_by(external_id: params[:id]) || Release.find_by(id: params[:id])
  end

  def release_params
    params.require(:release).permit(:title, :genre, :publisher, :release_date, :status, tracks_attributes: [:id, :title, :pos, :_destroy])
  end
end
