class Release < ApplicationRecord
  belongs_to :artist
  has_many :tracks, dependent: :destroy
  has_one_attached :cover

  validates :title, presence: true, uniqueness: true
end
