class ReleasesController < ApplicationController
  before_action :set_release, only: %i[show download]

  def show
    @tracks = @release&.tracks&.published&.by_position
    @md_description = MarkdownRenderer.call(@release.description) if @release&.description.present?
    @release_plays_count = StatEvent.plays.where(release_id: @release.id).count
  end

  def download
    return head :not_found unless @release&.published? && @release.allow_zip_download?
    # Speculative prefetches and HEAD probes must not build the ZIP at all —
    # that wastes CPU/IO and used to record a second download event per click.
    return head :ok if prefetch_request?

    blob = ReleaseZipCache.new(@release).blob
    StatTracker.record_download(release: @release, request: request)
    send_data blob.download,
              filename: blob.filename.to_s.delete_prefix("#{@release.zip_version}--"),
              type: 'application/zip',
              disposition: 'attachment'
  end

  private

  # Turbo 8 sends "X-Sec-Purpose: prefetch" on speculative GETs; browsers and
  # CDNs may use "Purpose"/"Sec-Purpose" instead. None of them is a real click,
  # so they must not build the ZIP or create a download stat_event.
  def prefetch_request?
    request.head? || %w[Purpose Sec-Purpose X-Sec-Purpose].any? do |header|
      request.headers[header].to_s.include?('prefetch')
    end
  end

  def set_release
    @release = find_short_codeable!(public_scope: Release.published, param: params[:id])
  end
end
