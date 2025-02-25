class Release < ApplicationRecord
  belongs_to :artist
  has_many :tracks, dependent: :destroy
  has_one_attached :cover

  validates :title, presence: true, uniqueness: true

  def update_plays_count!
    update_column(:plays_count, tracks.sum(:plays_count))
  end

  def artists
    tracks.includes(:artists).map(&:artists).flatten.uniq
  end
end
