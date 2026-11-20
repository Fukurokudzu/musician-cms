# A statistics report generated in the background by StatsExportJob.
# The report itself is attached via Active Storage; the row tracks
# status/progress so the admin UI can show a progress bar while the
# (potentially heavy) aggregation runs. Stale exports are purged
# opportunistically when a new one is requested.
class StatsExport < ApplicationRecord
  KINDS = %w[csv xlsx].freeze
  STATUSES = %w[pending running done failed].freeze
  RETAIN_FOR = 24.hours

  has_one_attached :file

  validates :kind, inclusion: { in: KINDS }
  validates :status, inclusion: { in: STATUSES }
  validates :range, presence: true

  scope :recent, -> { order(created_at: :desc) }

  def percent = progress.clamp(0, 100)

  def pending? = status == 'pending'
  def running? = status == 'running'
  def done? = status == 'done'
  def failed? = status == 'failed'

  def in_flight? = pending? || running?

  def filename
    "musician-cms-stats-#{range}-#{created_at.strftime('%Y%m%d-%H%M%S')}.#{kind}"
  end

  def content_type
    kind == 'xlsx' ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' : 'text/csv'
  end

  def mark_running!(progress)
    update!(status: 'running', progress: progress.clamp(0, 99))
  end

  def mark_done!(row_count:)
    update!(status: 'done', progress: 100, row_count:)
  end

  def mark_failed!(error)
    update!(status: 'failed', error_message: error.to_s.truncate(500))
  end

  # Drops exports older than RETAIN_FOR together with their files.
  def self.purge_stale!
    where(created_at: ...RETAIN_FOR.ago).find_each(&:destroy)
  end
end
