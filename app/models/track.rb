class Track < ApplicationRecord
  belongs_to :release
  has_many :artists, through: :release

  has_one_attached :audio_file

  def increment_plays!
    increment!(:plays_count)
    release.increment!(:plays_count)
    artists.each { |artist| artist.increment!(:plays_count) }
  end
end
