class Artist < ApplicationRecord
  has_many :releases, dependent: :destroy
  has_many :tracks, through: :releases

  validates :title, presence: true, uniqueness: true
  has_one_attached :photo

  enum role: { producer: 0, singer: 1, composer: 2, lyricist: 3, arranger: 4, performer: 5, band: 6, other: 7 }
end
