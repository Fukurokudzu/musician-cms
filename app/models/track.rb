class Track < ApplicationRecord
  belongs_to :release
  has_many :artists, through: :release

  has_one_attached :audio_file

  def increment_plays!
    increment!(:plays_count)
    release.increment!(:plays_count)
    artists.each { |artist| artist.increment!(:plays_count) }
  end

  def duration_formatted
    return '--:--' unless duration

    minutes = (duration / 60).floor
    seconds = duration % 60
    format('%d:%02d', minutes, seconds)
  end

  def update_duration!
    return unless audio_file.attached?

    file_path = ActiveStorage::Blob.service.send(:path_for, audio_file.key)
    audio = WahWah.open(file_path)
    self.duration = audio.duration.round
    save
  end
end
