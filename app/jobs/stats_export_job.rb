require 'fileutils'

# Generates a StatsExport in the background: aggregates every stat the admin
# stats page shows (full catalogue, not just the paginated views) and writes
# it to CSV or XLSX. Progress is persisted on the StatsExport row so the
# admin UI can poll it and render a progress bar.
class StatsExportJob < ApplicationJob
  queue_as :default

  def perform(export_id, range)
    export = StatsExport.find_by(id: export_id)
    return if export.nil? || export.done?

    export.mark_running!(5)
    builder = StatsReportBuilder.new(range:) do |percent|
      export.mark_running!(percent)
    end
    builder.sections # force aggregation before we claim we're writing the file
    row_count = builder.row_count

    file_path = Rails.root.join('tmp', "stats-export-#{export.id}.#{export.kind}")

    case export.kind
    when 'csv'
      File.write(file_path, builder.to_csv)
    when 'xlsx'
      builder.to_xlsx(file_path)
    else
      raise "Unknown export kind: #{export.kind.inspect}"
    end

    export.file.attach(io: File.open(file_path, 'rb'), filename: export.filename, content_type: export.content_type)
    export.mark_done!(row_count:)

    AuditLogger.log(action: 'stats.export_completed', actor: 'system',
                    metadata: { export_id: export.id, kind: export.kind, range:, row_count: })
  rescue StandardError => e
    Rails.logger.error "StatsExportJob failed: #{e.class}: #{e.message}"
    Rails.logger.error e.backtrace.first(20).join("\n")
    export&.mark_failed!("#{e.class}: #{e.message}")
    AuditLogger.log(action: 'stats.export_failed', actor: 'system',
                    metadata: { export_id: export_id, error: "#{e.class}: #{e.message}" })
  ensure
    FileUtils.rm_f(file_path) if file_path.present?
  end
end
