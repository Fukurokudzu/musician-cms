class ReleasesController < ApplicationController
  before_action :set_release, only: %i[show download]

  def show
    @tracks = @release&.tracks&.published&.by_position
    @md_description = MarkdownRenderer.call(@release.description) if @release&.description.present?
  end

  def download
    return head :not_found unless @release&.published? && @release.allow_zip_download?

    builder = ReleaseZipBuilder.new(@release)
    data = builder.call
    StatTracker.record_download(release: @release, request: request)
    send_data data,
              filename: builder.filename,
              type: 'application/zip',
              disposition: 'attachment'
  end

  private

  def set_release
    @release = find_short_codeable!(public_scope: Release.published, param: params[:id])
  end
end
