class AddDefaultTrack < ActiveRecord::Migration[6.0]
  def up
    artist = Artist.create!(title: 'Default Artist')
    release = Release.create!(title: 'Default Release', artist:)
    track = Track.create!(title: 'Default Track', release:)
    track.audio_file.attach(
      io: File.open(Rails.root.join('app', 'music', 'Default artist', 'Default release',
                                    'Default track.mp3')), filename: 'Default track.mp3')

  end

  def down
    track = Track.find_by(title: 'Default Track')
    track.audio_file.purge if track&.audio_file&.attached?
    track&.destroy
    Release.find_by(title: 'Default Release')&.destroy
    Artist.find_by(title: 'Default Artist')&.destroy
  end
end
