class Release < ApplicationRecord
  belongs_to :artist
  has_many :tracks, dependent: :destroy
  has_one_attached :cover

  validates :title, presence: true, uniqueness: true

  scope :active, -> { joins(:artist).where(artists: { soft_deleted: false }) }

  def duration
    tracks.sum(:duration)
  end

  def duration_humanized
    hours = (duration / 3600).floor
    minutes = ((duration % 3600) / 60).floor
    seconds = duration % 60

    if hours.positive?
      format('%d:%02d:%02d', hours, minutes, seconds)
    else
      format('%d:%02d', minutes, seconds)
    end
  end

  def update_plays_count!
    update_column(:plays_count, tracks.sum(:plays_count))
  end

  def artists
    tracks.includes(:artists).map(&:artists).flatten.uniq
  end
end
