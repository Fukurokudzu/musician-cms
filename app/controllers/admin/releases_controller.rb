class Admin::ReleasesController < ApplicationController
  include AdminAuthorization

  before_action :set_release, only: [:show, :edit, :update, :destroy, :add_tracks, :bulk_update_tracks]

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

  def bulk_update_tracks
    ids = Array(params[:track_ids]).map(&:to_s)
    tracks = @release.tracks.where(id: ids)
    attrs = bulk_track_attributes
    if attrs.present?
      tracks.update_all(attrs.merge(updated_at: Time.current))
      flash.now[:success] = t('admin.release.flash.tracks_published', default: 'Tracks updated')
    else
      flash.now[:error] = t('admin.release.flash.bulk_no_action', default: 'Choose an action')
    end
    render turbo_stream: [
      turbo_stream.update('admin_body', partial: 'edit'),
      turbo_stream.update('flash', partial: 'layouts/flash')
    ]
  rescue StandardError => e
    flash.now[:error] = e.message
    render turbo_stream: [
      turbo_stream.update('admin_body', partial: 'edit'),
      turbo_stream.update('flash', partial: 'layouts/flash')
    ]
  end


  def bulk_update
    ids = Array(params[:release_ids]).map(&:to_s)
    releases = Release.where(id: ids.select { |id| id.match?(/\A\d+\z/) })
    releases = releases.or(Release.where(external_id: ids)) if ids.any? { |id| !id.match?(/\A\d+\z/) }
    attrs = bulk_release_attributes
    if attrs.present?
      releases.update_all(attrs.merge(updated_at: Time.current))
      flash.now[:success] = t('admin.release.flash.releases_updated', default: 'Releases updated')
    else
      flash.now[:error] = t('admin.release.flash.bulk_no_action', default: 'Choose an action')
    end
    render turbo_stream: [
      turbo_stream.update('admin_body', partial: 'system'),
      turbo_stream.update('flash', partial: 'layouts/flash')
    ]
  rescue StandardError => e
    flash.now[:error] = e.message
    render turbo_stream: [
      turbo_stream.update('admin_body', partial: 'system'),
      turbo_stream.update('flash', partial: 'layouts/flash')
    ]
  end


  def update
    if @release.update(release_params)
      if params[:bulk_apply].present?
        attrs = bulk_track_attributes
        attrs = { status: params[:bulk_status] } if attrs.blank? && params[:bulk_status].present?
        if attrs.present?
          @release.tracks.where(id: Array(params[:track_ids])).update_all(attrs.merge(updated_at: Time.current))
        end
        flash.now[:success] = t('admin.release.flash.updated')
        render turbo_stream: [
          turbo_stream.update('admin_body', partial: 'edit'),
          turbo_stream.update('flash', partial: 'layouts/flash')
        ]
      else
        flash.now[:success] = t('admin.release.flash.updated')
        render_release_show
      end
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

  def bulk_track_attributes
    attrs = {}
    top = params.permit(:title, :pos, :status)
    attrs.merge!(top.to_h)
    if params[:track].present?
      attrs.merge!(params.require(:track).permit(:title, :pos, :status).to_h)
    end
    attrs.delete_if { |_, value| value.nil? || (value.is_a?(String) && value.blank?) }
    attrs.transform_values { |value| value == 'true' ? true : (value == 'false' ? false : value) }
  end

  def bulk_release_attributes
    attrs = {}
    top = params.permit(:title, :genre, :publisher, :release_date, :status, :allow_zip_download, :description)
    attrs.merge!(top.to_h)
    if params[:release].present? && params[:release].is_a?(ActionController::Parameters)
      attrs.merge!(params.require(:release).permit(:title, :genre, :publisher, :release_date, :status, :allow_zip_download, :description).to_h)
    end
    attrs.delete_if { |_, value| value.nil? || (value.is_a?(String) && value.blank?) }
    attrs.transform_values { |value| value == 'true' ? true : (value == 'false' ? false : value) }
  end

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
