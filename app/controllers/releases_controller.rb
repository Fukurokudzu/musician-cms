class ReleasesController < ApplicationController
  before_action :set_release, only: [:show, :download]

  def index
  end

  def show
    @tracks = @release&.tracks
    @md_description = MarkdownRenderer.call(@release.description) if @release&.description.present?
  end

  def download
    return head :not_found unless @release&.published? && @release&.allow_zip_download?

    builder = ReleaseZipBuilder.new(@release)
    send_data builder.call,
              filename: builder.filename,
              type: 'application/zip',
              disposition: 'attachment'
  end

  private

  def set_release
    @release = Release.published.find_by(external_id: params[:id]) ||
               Release.published.find_by(id: params[:id])
    raise ActiveRecord::RecordNotFound unless @release
  end
end
