class RemoveDefaultTrackPlaceholder < ActiveRecord::Migration[7.2]
  def up
    artist = Artist.find_by(title: 'Default Artist')
    return unless artist

    artist.releases.find_by(title: 'Default Release')&.destroy
    artist.destroy unless artist.releases.exists?
  end

  def down
    # The placeholder artist/release/track seeded by the removed
    # AddDefaultTrack migration cannot be restored automatically.
  end
end
