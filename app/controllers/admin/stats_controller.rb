module Admin
  class StatsController < ApplicationController
    include AdminAuthorization

    def show
      @range = sanitized_range(params[:range])

      @report = StatsReport.new(
        range: @range,
        sort: params[:sort], dir: params[:dir], page: params[:page],
        dsort: params[:dsort], ddir: params[:ddir], dpage: params[:dpage]
      )
      @latest_export = StatsExport.recent.first

      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.update('admin_body', partial: 'admin/stats/stats') }
        # Plain GETs (e.g. a link opened in a new tab or a Turbo fallback) must
        # land on the statistics tab itself, with the requested range intact,
        # instead of bouncing back to the default System tab.
        format.html { render :show }
      end
    end

    # Kicks off a background export of everything the stats page shows
    # (full catalogue, not just the paginated views). Responds with the
    # export panel partial so Turbo swaps it in and the progress polling
    # starts.
    def export
      StatsExport.purge_stale!
      range = sanitized_range(params[:range])
      kind = params[:kind].to_s
      kind = 'csv' unless StatsExport::KINDS.include?(kind)
      @range = range

      record = StatsExport.create!(kind:, range:)
      StatsExportJob.perform_later(record.id, range)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update('stats-export-inner', partial: 'admin/stats/export_panel',
                                                                         locals: { export: record })
        end
        format.html { redirect_to admin_stats_path }
      end
    end

    # Polled by the stats-export Stimulus controller while an export runs.
    def export_status
      record = StatsExport.find_by(id: params[:id])
      if record.nil?
        render json: { status: 'failed', error: 'not found' }, status: :not_found
        return
      end

      render json: {
        status: record.status,
        progress: record.percent,
        download_url: (record.done? ? export_download_admin_stats_path(record) : nil),
        error: (record.failed? ? record.error_message : nil)
      }
    end

    def export_download
      record = StatsExport.find(params[:id])
      raise ActiveRecord::RecordNotFound unless record.done? && record.file.attached?

      send_data record.file.download, filename: record.filename,
                                      type: record.content_type,
                                      disposition: 'attachment'
    end

    private

    def sanitized_range(value)
      range = value.presence || '30'
      range = '30' unless StatEvent::RANGES.key?(range) || range == 'all'
      range
    end
  end
end
