class Artist < ApplicationRecord
  has_many :releases, dependent: :destroy
  has_many :tracks, through: :releases

  validates :title, presence: true, uniqueness: true
  has_one_attached :photo
end
