class Admin::ReleasesController < ApplicationController
  include AdminAuthorization

  before_action :set_release, only: [:show, :edit, :update, :destroy]

  def index
    render turbo_stream: turbo_stream.update('admin_body', partial: 'system')
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
      if params[:tracks].present?
        params[:tracks].each_with_index do |track_file, index|
          next if track_file.blank?
          track = @release.tracks.new(
            title: File.basename(track_file.original_filename, File.extname(track_file.original_filename)),
            pos: index + 1,
            status: :draft
          )
          track.audio_file.attach(track_file)
          track.save!
        end
      end
      flash.now[:success] = 'Release uploaded'
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

  def destroy
    if @release.destroy
      flash.now[:success] = 'Release deleted'
      render turbo_stream: turbo_stream.update('admin_body', partial: 'system')
    else
      flash.now[:error] = 'Could not delete release'
      render turbo_stream: turbo_stream.update('flash', partial: 'layouts/flash')
    end
  end

  private

  def set_release
    @release = Release.find_by(external_id: params[:id]) || Release.find_by(id: params[:id])
  end

  def release_params
    params.require(:release).permit(:title, :genre, :publisher, :release_date, :status, tracks_attributes: [:id, :title, :pos, :status, :_destroy])
  end
end
