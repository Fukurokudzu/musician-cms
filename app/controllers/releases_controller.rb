class ReleasesController < ApplicationController
  before_action :set_release, only: [:show, :download]

  def index
  end

  def show
    @tracks = @release&.tracks
  end

  def download
    return head :not_found unless @release&.allow_zip_download?

    builder = ReleaseZipBuilder.new(@release)
    send_data builder.call,
              filename: builder.filename,
              type: 'application/zip',
              disposition: 'attachment'
  end

  private

  def set_release
    @release = Release.find_by(external_id: params[:id]) || Release.find_by(id: params[:id])
  end
end
