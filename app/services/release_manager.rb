class ReleaseManager
  include ScanLibHelper

  def initialize(artist_folders)
    @artist_folders = artist_folders
  end

  def update_releases
    @artist_folders.each_pair do |artist, artist_path|
      releases = ScanLibHelper.get_folders_list(artist_path)
      releases.each_pair do |release, release_path|
        tracks = ScanLibHelper.get_tracks_list(release_path)
        metadata = extract_tracks_metadata(tracks)
        cover = ScanLibHelper.get_release_cover(release_path)

        update_release(artist, release, tracks, metadata, cover)
      end
    end
  end

  private

  def extract_tracks_metadata(tracks)
    tracks.transform_values do |track_path|
      begin
        audio = WahWah.open(track_path)
        {
          title: audio.title,
          track_number: audio.track,
          duration: audio.duration&.round
        }
      rescue StandardError => e
        Rails.logger.error("Failed to extract metadata from #{track_path}: #{e.message}")
        { title: nil, track_number: nil, duration: nil }
      end
    end
  end

  def update_release(artist, release, tracks, metadata, cover)
    artist_record = Artist.find_by!(title: artist)
    release_record = artist_record.releases.find_or_create_by!(title: release)
    attach_cover(release_record, cover)
    update_tracks(release_record, tracks, metadata)
    update_track_positions(release_record)
  end

  def attach_cover(release, cover_path)
    return unless cover_path

    release.cover.attach(io: File.open(cover_path), filename: File.basename(cover_path))
  rescue StandardError => e
    Rails.logger.error("Failed to attach cover for release #{release.title}: #{e.message}")
  end

  def update_tracks(release, tracks, metadata)
    tracks.each do |filename, track_path|
      track_info = metadata[filename] || {}
      track_title = track_info[:title].presence || File.basename(track_path, File.extname(track_path))

      begin
        track_record = release.tracks.find_or_create_by!(title: track_title)
        attach_audio_file(track_record, track_path)
        track_record.duration = track_info[:duration]
        track_record.pos = track_info[:track_number]
        track_record.save!
      rescue StandardError => e
        Rails.logger.error("Failed to update track #{track_title} for release #{release.title}: #{e.message}")
      end
    end
  end

  def attach_audio_file(track, track_path)
    track.audio_file.attach(io: File.open(track_path), filename: File.basename(track_path))
  rescue StandardError => e
    Rails.logger.error("Failed to attach audio file for track #{track.title}: #{e.message}")
  end

  def update_track_positions(release)
    tracks = release.tracks.order(:pos, :id)
    tracks.each_with_index do |track, index|
      begin
        track.pos = index + 1
        track.save!
      rescue StandardError => e
        Rails.logger.error("Failed to update position for track #{track.title}: #{e.message}")
      end
    end
  end
end
