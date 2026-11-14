class Admin::ReleasesController < ApplicationController
  include AdminAuthorization

  before_action :set_release, only: [:show, :edit, :update, :destroy, :add_tracks]

  def index
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.update('admin_body', partial: 'system') }
      format.html { redirect_to admin_path }
    end
  end

  def show
    render turbo_stream: turbo_stream.update('admin_body', partial: 'show')
  end

  def edit
    render turbo_stream: turbo_stream.update('admin_body', partial: 'edit')
  end

  def new_upload
    @artists = Artist.all
    @release = Release.new
    render turbo_stream: turbo_stream.update('admin_body', partial: 'new_upload')
  end

  def upload
    @artist = Artist.find_by(id: params[:artist_id]) || Artist.new(title: params[:artist_title])
    @artist.save! if @artist.new_record?

    @release = @artist.releases.new(
      title: params[:release_title].presence,
      genre: params[:genre],
      publisher: params[:publisher],
      release_date: params[:release_date].presence,
      status: params[:status].presence || :draft
    )
    @release.cover.attach(params[:cover]) if params[:cover].present?

    if @release.save
      @release.add_tracks!(params[:tracks])
      flash.now[:success] = t('admin.release.flash.uploaded')
      render turbo_stream: turbo_stream.update('admin_body', partial: 'system')
    else
      @artists = Artist.all
      flash.now[:error] = @release.errors.full_messages.join(', ')
      render turbo_stream: [
        turbo_stream.update('admin_body', partial: 'new_upload'),
        turbo_stream.update('flash', partial: 'layouts/flash')
      ]
    end
  rescue StandardError => e
    @artists = Artist.all
    flash.now[:error] = e.message
    render turbo_stream: [
      turbo_stream.update('admin_body', partial: 'new_upload'),
      turbo_stream.update('flash', partial: 'layouts/flash')
    ]
  end

  def add_tracks
    tracks = @release.add_tracks!(params[:tracks], after_pos: @release.tracks.maximum(:pos).to_i)

    if tracks.empty?
      flash.now[:error] = t('admin.release.flash.no_track_file')
    else
      flash.now[:success] = t('admin.release.flash.tracks_added', count: tracks.size)
    end

    render_release_show
  rescue StandardError => e
    flash.now[:error] = e.message
    render_release_show
  end

  def update
    if @release.update(release_params)
      flash.now[:success] = t('admin.release.flash.updated')
      render_release_show
    else
      flash.now[:error] = @release.errors.full_messages.join(', ')
      render turbo_stream: turbo_stream.update('flash', partial: 'layouts/flash'), status: :unprocessable_entity
    end
  end

  def destroy
    if @release.destroy
      flash.now[:success] = t('admin.release.flash.deleted')
      render turbo_stream: turbo_stream.update('admin_body', partial: 'system')
    else
      flash.now[:error] = t('admin.release.flash.delete_failed')
      render turbo_stream: turbo_stream.update('flash', partial: 'layouts/flash')
    end
  end

  private

  def set_release
    @release = Release.find_by(external_id: params[:id]) || Release.find_by(id: params[:id])
  end

  def render_release_show
    render turbo_stream: [
      turbo_stream.update('admin_body', partial: 'show'),
      turbo_stream.update('flash', partial: 'layouts/flash')
    ]
  end

  def release_params
    params.require(:release).permit(:title, :genre, :publisher, :release_date, :status, :allow_zip_download, :description, tracks_attributes: [:id, :title, :pos, :status, :_destroy])
  end
end
