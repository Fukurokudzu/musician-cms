class Track < ApplicationRecord
  belongs_to :release
  has_many :artists, through: :release

  has_one_attached :audio_file
end
