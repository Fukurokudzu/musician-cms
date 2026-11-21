require 'csv'
require 'fast_excel'

# Builds the statistics report that StatsExportJob generates in the background.
# Sections are plain [{headers:, rows:}] structures shared by the CSV and
# XLSX writers, so both formats always carry identical data:
#
#   Summary          — headline counters for the selected range
#   Daily activity   — the same buckets the line chart uses (days or months)
#   Tracks           — every track in the library, with period/total stats
#   Releases         — every release, with period/total stats
#   Geography        — per-country breakdown (or a note when GeoIP is absent)
#
# Progress is reported through the +on_progress+ callback so the job can
# persist it on the StatsExport row for the UI progress bar.
class StatsReportBuilder
  def initialize(range: '30', on_progress: nil)
    @range = StatEvent::RANGES.key?(range.to_s) || range.to_s == 'all' ? range.to_s : '30'
    @on_progress = on_progress
    @report = StatsReport.new(range: @range)
  end

  # Ordered { section_name => { headers:, rows: } }
  def sections
    @sections ||= {
      'Summary' => summary_section,
      'Daily activity' => daily_section,
      'Tracks' => tracks_section,
      'Releases' => releases_section,
      'Geography' => geo_section
    }
  end

  def row_count
    sections.values.sum { |section| section[:rows].size }
  end

  def to_csv
    @on_progress&.call(90)
    csv = CSV.generate(encoding: 'UTF-8') do |out|
      out << ["Musician CMS — statistics report"]
      out << ["Range: #{range_label}", "Generated at: #{format_time(Time.current)}"]
      sections.each do |name, section|
        out << []
        out << [name]
        out << section[:headers]
        section[:rows].each { |row| out << row }
      end
    end
    "\uFEFF#{csv}" # BOM so Excel opens the UTF-8 correctly
  end

  def to_xlsx(path)
    @on_progress&.call(90)
    workbook = FastExcel.open(path.to_s)
    bold = workbook.bold_format
    sections.each do |name, section|
      worksheet = workbook.add_worksheet(name.truncate(31, omission: ''))
      section[:headers].each_with_index do |header, index|
        worksheet.set_column(index, index, [header.to_s.length + 2, 12].max.clamp(12, 60))
      end
      worksheet.append_row(section[:headers], bold)
      section[:rows].each { |row| worksheet.append_row(row) }
    end
    workbook.close
    path
  end

  private

  def progress(percent)
    @on_progress&.call(percent)
  end

  def events = @report.events
  def plays = events.plays
  def downloads = events.downloads

  def summary_section
    summary = @report.summary
    headers = %w[Metric Value]
    rows = [
      ['Range', range_label],
      ['Generated at', format_time(Time.current)],
      ['Plays (period)', summary[:plays_period]],
      ['Downloads (period)', summary[:downloads_period]],
      ['Unique listeners (period)', summary[:unique_listeners]],
      ['Countries (period)', summary[:countries_count]],
      ['Plays (all time)', summary[:plays_all_time]],
      ['Downloads (all time)', summary[:downloads_all_time]],
      ['Tracks in library', Track.count],
      ['Releases in library', Release.count]
    ]
    progress(20)
    { headers:, rows: }
  end

  def daily_section
    headers = %w[Date Plays Downloads]
    rows = @report.daily_series.map { |row| [row[:key].to_s, row[:plays], row[:downloads]] }
    progress(35)
    { headers:, rows: }
  end

  def tracks_section
    period_counts = plays.group(:track_id).count
    total_counts = @report.total_plays_by_track

    headers = ['ID', 'Title', 'Artist', 'Release', 'Status', 'Position',
               'Plays (period)', 'Plays (total)', 'Duration (s)', 'Created at']
    rows = []
    Track.includes(release: :artist).order(:id).find_each do |track|
      rows << [
        track.id,
        track.title,
        track.release&.artist&.title,
        track.release&.title,
        track.status,
        track.pos,
        period_counts[track.id] || 0,
        total_counts[track.id] || 0,
        track.duration,
        format_time(track.created_at)
      ]
    end
    progress(60)
    { headers:, rows: }
  end

  def releases_section
    period_downloads = downloads.group(:release_id).count
    period_plays = plays.group(:release_id).count
    total_downloads = @report.total_downloads_by_release
    total_plays = @report.total_plays_by_release

    headers = ['ID', 'Title', 'Artist', 'Status', 'Release date', 'Genre',
               'ZIP download', 'Downloads (period)', 'Downloads (total)',
               'Plays (period)', 'Plays (total)', 'Created at']
    rows = []
    Release.includes(:artist).order(:id).find_each do |release|
      rows << [
        release.id,
        release.title,
        release.artist&.title,
        release.status,
        release.release_date&.iso8601,
        release.genre,
        release.allow_zip_download? ? 'yes' : 'no',
        period_downloads[release.id] || 0,
        total_downloads[release.id] || 0,
        period_plays[release.id] || 0,
        total_plays[release.id] || 0,
        format_time(release.created_at)
      ]
    end
    progress(80)
    { headers:, rows: }
  end

  def geo_section
    headers = ['Country code', 'Country', 'Plays', 'Downloads', 'Unique listeners']
    if @report.geo_available?
      rows = @report.geo_rows(limit: nil).map { |row| [row.country_code, row.country_name, row.plays, row.downloads, row.unique_listeners] }
    else
      rows = [['-', I18n.t('admin.stats.geo_missing_db'), nil, nil, nil]]
    end
    progress(90)
    { headers:, rows: }
  end

  def range_label
    case @range
    when 'all' then 'All time'
    else
      days = { '7' => 7, '30' => 30, '90' => 90, '365' => 365 }[@range]
      "Last #{days} days (#{(days - 1).days.ago.to_date.iso8601}..#{Date.current.iso8601})"
    end
  end

  def format_time(time)
    time&.strftime('%Y-%m-%d %H:%M:%S')
  end
end
