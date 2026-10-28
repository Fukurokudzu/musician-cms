class ArtistManager
  def initialize(artist_folders)
    @artist_folders = artist_folders
  end

  def create_artists
    matched_artist_ids = []

    @artist_folders.each_pair do |artist, artist_path|
      artist_record = nil
      begin
        artist_record = Artist.find_by(path: artist_path)
      rescue StandardError
      end
      artist_record ||= Artist.find_by(title: artist)
      artist_record ||= Artist.new

      artist_record.title = artist
      begin
        artist_record.path = artist_path if artist_record.respond_to?(:path=)
      rescue StandardError
      end
      artist_record.save!
      matched_artist_ids << artist_record.id
    end

    remove_deleted_artists(matched_artist_ids)
  end

  def remove_deleted_artists(matched_artist_ids = [])
    Artist.find_each do |artist|
      next if matched_artist_ids.include?(artist.id)

      if artist.respond_to?(:path) && artist.path.present?
        next if @artist_folders.values.include?(artist.path)
      end

      next if @artist_folders.key?(artist.title)

      artist.releases.each do |release|
        release.cover.purge if release.cover.attached?
        release.tracks.each { |track| track.audio_file.purge if track.audio_file.attached? }
      end
      artist.destroy
    end
  end
end
