# Aggregates stat_events into everything the admin stats page renders:
# headline counters, the daily plays/downloads series, per-release bars,
# paginated+sortable track and release tables and the per-country breakdown.
#
# stat_events is the single source of truth: period columns, charts and all-time
# totals are all derived from recorded events.
class StatsReport
  TRACK_SORTS = %w[title release period total].freeze
  RELEASE_SORTS = %w[release period total].freeze
  PER_PAGE = 15
  TOP_RELEASES = 10
  TOP_COUNTRIES = 15

  TrackRow = Data.define(:id, :title, :release_id, :release_title, :period_plays, :total_plays)
  ReleaseRow = Data.define(:id, :title, :period_downloads, :total_downloads)
  CountryRow = Data.define(:country_code, :country_name, :plays, :downloads, :unique_listeners)

  attr_reader :range, :page, :dpage, :sort, :dir, :dsort, :ddir

  def initialize(range: '30', sort: 'total', dir: 'desc', page: 1, dsort: 'total', ddir: 'desc', dpage: 1)
    @range = StatEvent::RANGES.key?(range.to_s) || range.to_s == 'all' ? range.to_s : '30'
    @sort = TRACK_SORTS.include?(sort) ? sort : 'total'
    @dir = dir.to_s == 'asc' ? 'asc' : 'desc'
    @page = [page.to_i, 1].max
    @dsort = RELEASE_SORTS.include?(dsort) ? dsort : 'total'
    @ddir = ddir.to_s == 'asc' ? 'asc' : 'desc'
    @dpage = [dpage.to_i, 1].max
  end

  def events
    @events ||= StatEvent.in_range(range)
  end

  delegate :plays, to: :events

  delegate :downloads, to: :events

  def total_plays_by_track
    @total_plays_by_track ||= StatEvent.plays.group(:track_id).count
  end

  def total_plays_by_release
    @total_plays_by_release ||= StatEvent.plays.group(:release_id).count
  end

  def total_downloads_by_release
    @total_downloads_by_release ||= StatEvent.downloads.group(:release_id).count
  end

  def period_days
    { '7' => 7, '30' => 30, '90' => 90, '365' => 365 }[range]
  end

  def summary
    {
      plays_period: plays.count,
      downloads_period: downloads.count,
      unique_listeners: plays.where.not(ip_hash: nil).distinct.count(:ip_hash),
      countries_count: plays.where.not(country_code: nil).distinct.count(:country_code),
      plays_all_time: StatEvent.plays.count,
      downloads_all_time: StatEvent.downloads.count
    }
  end

  # [{label:, value:}] — used by the horizontal bar chart, top releases by
  # period plays. Falls back to nothing when there are no events yet.
  def top_releases(limit: TOP_RELEASES)
    @top_releases ||= begin
      grouped = plays.where.not(release_title: nil)
                     .group(:release_id, :release_title)
                     .order(Arel.sql('COUNT(*) DESC'))
                     .limit(limit)
                     .count
      grouped.map do |(release_id, title), count|
        { release_id:, label: title.presence || '—', value: count }
      end
    end
  end

  def max_release_plays
    top_releases.map { |row| row[:value] }.max || 0
  end

  # Continuous buckets (days, or months for very long spans) for the line chart.
  # Returns [{key:, label:, plays:, downloads:}]
  def daily_series
    @daily_series ||= begin
      monthly = use_months?
      buckets = bucket_range(monthly)

      group_expr = monthly ? "date_trunc('month', created_at)" : "date_trunc('day', created_at)"

      plays_by_bucket = plays.group(Arel.sql(group_expr)).count.transform_keys { |t| bucket_key(t, monthly) }
      downloads_by_bucket = downloads.group(Arel.sql(group_expr)).count.transform_keys { |t| bucket_key(t, monthly) }

      buckets.map do |key|
        {
          key:,
          label: bucket_label(key, monthly),
          plays: plays_by_bucket[key] || 0,
          downloads: downloads_by_bucket[key] || 0
        }
      end
    end
  end

  def max_series_value
    daily_series.map { |row| [row[:plays], row[:downloads]].max }.max || 0
  end

  # All tracks (even if never played), sorted by +sort+ and paginated.
  def track_page
    rows = sorted_track_rows
    paginate(rows, @page)
  end

  def track_total_pages
    [(sorted_track_rows.length / PER_PAGE.to_f).ceil, 1].max
  end

  # All releases (even if never downloaded), sorted by +dsort+ and paginated.
  def release_page
    rows = sorted_release_rows
    paginate(rows, @dpage)
  end

  def release_total_pages
    [(sorted_release_rows.length / PER_PAGE.to_f).ceil, 1].max
  end

  def geo_rows(limit: TOP_COUNTRIES)
    counts = events.where.not(country_code: nil)
                   .group(:country_code, :country_name, :kind)
                   .count
    # Unique visitors per country, counted across both plays and downloads:
    # a country that only produced downloads still has unique visitors.
    uniques = events.where.not(country_code: nil)
                    .where.not(ip_hash: nil)
                    .group(:country_code)
                    .distinct
                    .count(:ip_hash)

    by_country = Hash.new do |hash, code|
      hash[code] = { country_code: code, country_name: code, plays: 0, downloads: 0, unique_listeners: 0 }
    end

    counts.each do |(code, name, kind), count|
      row = by_country[code]
      row[:country_name] = name.presence || code
      row[kind == 'play' ? :plays : :downloads] += count
    end
    uniques.each { |code, count| by_country[code][:unique_listeners] = count }

    by_country.values
              .map { |row| CountryRow.new(**row) }
              .sort_by { |row| -(row.plays + row.downloads) }
              .then { |rows| limit.nil? ? rows : rows.first(limit) }
  end

  def geo_available?
    GeoIp.available?
  end

  private

  def series_monthly?
    use_months?
  end

  def use_months?
    (Date.current - series_first_date) > 400
  end

  def series_first_date
    @series_first_date ||= if range == 'all'
                             earliest = events.minimum(:created_at)
                             earliest ? earliest.to_date : Date.current
                           else
                             (period_days - 1).days.ago.to_date
                           end
  end

  def bucket_range(monthly)
    last = Date.current
    first = series_first_date

    if monthly
      months = []
      cursor = first.beginning_of_month
      while cursor <= last
        months << cursor.beginning_of_month.to_date
        cursor = cursor.next_month
      end
      months
    else
      (first..last).to_a
    end
  end

  def bucket_key(time, monthly)
    monthly ? time.to_date.beginning_of_month : time.to_date
  end

  def bucket_label(key, monthly)
    monthly ? I18n.l(key, format: '%b %Y') : I18n.l(key, format: '%d.%m')
  end

  def sorted_track_rows
    @sorted_track_rows ||= begin
      period_counts = plays.group(:track_id).count
      total_counts = total_plays_by_track

      rows = Track.includes(:release).map do |track|
        TrackRow.new(
          id: track.id,
          title: track.title.to_s,
          release_id: track.release_id,
          release_title: track.release&.title.to_s,
          period_plays: period_counts[track.id] || 0,
          total_plays: total_counts[track.id] || 0
        )
      end

      sort_rows(rows, @sort, @dir, track_sort_key)
    end
  end

  def sorted_release_rows
    @sorted_release_rows ||= begin
      period_counts = downloads.group(:release_id).count
      total_counts = total_downloads_by_release

      rows = Release.order(created_at: :desc, id: :desc).map do |release|
        ReleaseRow.new(
          id: release.id,
          title: release.title.to_s,
          period_downloads: period_counts[release.id] || 0,
          total_downloads: total_counts[release.id] || 0
        )
      end

      sort_rows(rows, @dsort, @ddir, release_sort_key)
    end
  end

  def track_sort_key
    lambda do |row, column|
      case column
      when 'title' then row.title.downcase
      when 'release' then row.release_title.downcase
      when 'period' then row.period_plays
      when 'total' then row.total_plays
      end
    end
  end

  def release_sort_key
    lambda do |row, column|
      case column
      when 'release' then row.title.downcase
      when 'period' then row.period_downloads
      when 'total' then row.total_downloads
      end
    end
  end

  # Ruby's sort_by is not stable, and reversing an ascending sort also flips
  # rows with equal values. Decorate with the original index instead: ties keep
  # the base order (newest first), like the admin releases list does in JS.
  def sort_rows(rows, column, direction, key_fn)
    rows.each_with_index
        .sort do |(left, left_index), (right, right_index)|
          comparison = key_fn.call(left, column) <=> key_fn.call(right, column)
          comparison = -comparison if direction == 'desc'
          comparison.nonzero? || (left_index <=> right_index)
        end
        .map(&:first)
  end

  def paginate(rows, page)
    rows.slice((page - 1) * PER_PAGE, PER_PAGE) || []
  end
end
