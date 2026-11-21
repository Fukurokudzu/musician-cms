class ReleasesController < ApplicationController
  before_action :set_release, only: %i[show download]

  def show
    @tracks = @release&.tracks&.published&.by_position
    @md_description = MarkdownRenderer.call(@release.description) if @release&.description.present?
  end

  def download
    return head :not_found unless @release&.published? && @release.allow_zip_download?
    # Speculative prefetches and HEAD probes must not build the ZIP at all —
    # that wastes CPU/IO and used to record a second download event per click.
    return head :ok if prefetch_request?

    builder = ReleaseZipBuilder.new(@release)
    data = builder.call
    StatTracker.record_download(release: @release, request: request)
    send_data data,
              filename: builder.filename,
              type: 'application/zip',
              disposition: 'attachment'
  end

  private

  # Turbo (and some CDNs) issue speculative GETs for visible links. They must
  # not be counted as real downloads — otherwise a single click records two
  # stat_events and every admin counter shows twice the real value.
  def prefetch_request?
    request.head? || request.headers['Purpose'].to_s.include?('prefetch') ||
      request.headers['Sec-Purpose'].to_s.include?('prefetch')
  end

  def set_release
    @release = find_short_codeable!(public_scope: Release.published, param: params[:id])
  end
end
