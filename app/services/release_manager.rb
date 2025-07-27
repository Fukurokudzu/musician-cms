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
        tags = get_tags(tracks)
        cover = ScanLibHelper.get_release_cover(release_path)

        update_release(artist, release, tracks, tags, cover)
      end
    end
  end

  private

  def get_tags(tracks)
    tracks.transform_values do |track_path|
      WahWah.open(track_path).title
    end
  end

  def update_release(artist, release, tracks, tags, cover)
    artist_record = Artist.find_by!(title: artist)
    release_record = artist_record.releases.find_or_create_by!(title: release)
    attach_cover(release_record, cover)
    update_tracks(release_record, tracks, tags)
  end

  def attach_cover(release, cover_path)
    return unless cover_path

    release.cover.attach(io: File.open(cover_path), filename: File.basename(cover_path))
  end

  def update_tracks(release, tracks, tags)
    tracks.each do |track, track_path|
      track_title = tags[track] || track
      track_record = release.tracks.find_or_create_by!(title: track_title)
      attach_audio_file(track_record, track_path)
      update_duration(track_record)
      track_record.save!
    rescue StandardError => e
      Rails.logger.error("Failed to update track #{track_title} for release #{release.title}: #{e.message}")
    end
  end

  def attach_audio_file(track, track_path)
    track.audio_file.attach(io: File.open(track_path), filename: File.basename(track_path))
  end

  def update_duration(track)
    return unless track.audio_file.attached?

    file_path = ActiveStorage::Blob.service.send(:path_for, track.audio_file.key)
    audio = WahWah.open(file_path)
    track.duration = audio.duration.round
  rescue StandardError => e
    Rails.logger.error("Failed to update duration for track #{track.title}: #{e.message}")
    track.duration = nil
  end
end
