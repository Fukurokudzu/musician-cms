class Release < ApplicationRecord
  belongs_to :artist
  has_many :tracks, dependent: :destroy

  validates :title, presence: true, uniqueness: true
end