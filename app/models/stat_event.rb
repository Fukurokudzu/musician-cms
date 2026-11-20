# Raw record of a single public play or download, written by StatTracker.
# Used by the admin stats page for charts and breakdowns; the denormalized
# *_title columns keep history meaningful after tracks are retitled or deleted.
class StatEvent < ApplicationRecord
  KINDS = %w[play download].freeze
  RANGES = { '7' => 7.days, '30' => 30.days, '90' => 90.days, '365' => 365.days }.freeze

  belongs_to :track, optional: true
  belongs_to :release, optional: true
  belongs_to :artist, optional: true

  validates :kind, inclusion: { in: KINDS }

  scope :plays, -> { where(kind: 'play') }
  scope :downloads, -> { where(kind: 'download') }
  scope :recent_first, -> { order(created_at: :desc) }

  # `range` is one of RANGES keys or 'all'.
  scope :in_range, lambda { |range|
    days = RANGES[range.to_s]
    days ? where('created_at >= ?', days.ago) : all
  }
end
