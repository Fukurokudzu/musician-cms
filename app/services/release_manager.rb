class ReleaseManager
  include ScanLibHelper

  def initialize(artist_folders)
    @artist_folders = artist_folders
  end

  def update_releases
    @artist_folders.each_pair do |artist, artist_path|
      releases = ScanLibHelper.get_folders_list(artist_path)
      artist_record = Artist.find_by(title: artist)
      next unless artist_record

      matched_release_ids = []

      releases.each_pair do |release, release_path|
        tracks = ScanLibHelper.get_tracks_list(release_path)
        metadata = extract_tracks_metadata(tracks)
        cover = ScanLibHelper.get_release_cover(release_path)

        release_record = update_release(artist, release, tracks, metadata, cover)
        matched_release_ids << release_record.id if release_record&.id
      end

      remove_deleted_releases(artist_record, releases, matched_release_ids)
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
    release_path = tracks.values.first&.then { |p| File.dirname(p) } || (cover ? File.dirname(cover) : nil)
    release_record = nil

    if release_path
      begin
        release_record = artist_record.releases.find_by(path: release_path)
      rescue StandardError
      end
    end
    release_record ||= artist_record.releases.find_by(title: release)
    release_record ||= artist_record.releases.new

    release_record.artist = artist_record
    if release_record.persisted?
      found_by_path = false
      begin
        found_by_path = release_record.respond_to?(:path) && release_record.path.present? && release_path && release_record.path == release_path
      rescue StandardError
      end
      if found_by_path
        # If found by path, don't overwrite a custom title
      else
        release_record.title = release
      end
    else
      release_record.title = release
    end
    release_record.release_date = Date.current if release_record.release_date.nil?
    begin
      release_record.path = release_path if release_record.respond_to?(:path=) && release_path
    rescue StandardError
    end
    release_record.save!

    attach_cover(release_record, cover)
    update_tracks(release_record, tracks, metadata)
    update_track_positions(release_record)
    remove_deleted_tracks(release_record, tracks)
    release_record
  end

  def attach_cover(release, cover_path)
    return unless cover_path

    if release.cover.attached?
      existing_filename = release.cover.blob.filename.to_s
      new_filename = File.basename(cover_path)
      return if existing_filename == new_filename
      release.cover.purge
    end

    release.cover.attach(io: File.open(cover_path), filename: File.basename(cover_path))
  rescue StandardError => e
    Rails.logger.error("Failed to attach cover for release #{release.title}: #{e.message}")
  end

  def update_tracks(release, tracks, metadata)
    tracks.each do |filename, track_path|
      track_info = metadata[filename] || {}
      track_title = track_info[:title].presence || File.basename(track_path, File.extname(track_path))

      begin
        track_record = nil
        begin
          track_record = release.tracks.find_by(path: track_path)
        rescue StandardError
        end
        track_record ||= release.tracks.find_by(title: track_title)
        track_record ||= release.tracks.new(release: release)

        track_record.release = release
        track_record.title = track_title
        begin
          track_record.path = track_path if track_record.respond_to?(:path=)
        rescue StandardError
        end
        track_record.duration = track_info[:duration]
        track_record.pos = track_info[:track_number]
        track_record.save!
        attach_audio_file(track_record, track_path)
      rescue StandardError => e
        Rails.logger.error("Failed to update track #{track_title} for release #{release.title}: #{e.message}")
      end
    end
  end

  def attach_audio_file(track, track_path)
    if track.audio_file.attached?
      existing_filename = track.audio_file.blob.filename.to_s
      new_filename = File.basename(track_path)
      return if existing_filename == new_filename
      track.audio_file.purge
    end

    track.audio_file.attach(io: File.open(track_path), filename: File.basename(track_path))
  rescue StandardError => e
    Rails.logger.error("Failed to attach audio file for track #{track.title}: #{e.message}")
  end

  def remove_deleted_tracks(release, tracks)
    existing_tracks = release.tracks.to_a
    existing_tracks.each do |track|
      if track.respond_to?(:path) && track.path.present?
        next if tracks.values.include?(track.path)
      end

      track_path = tracks.values.find { |p| File.basename(p) == (track.audio_file.blob.filename.to_s rescue nil) } if track.audio_file.attached?
      track_path ||= tracks[track.title] if tracks.key?(track.title)
      if track_path.nil?
        track.audio_file.purge if track.audio_file.attached?
        track.destroy
      end
    end
  rescue StandardError => e
    Rails.logger.error("Failed to remove deleted tracks for release #{release.title}: #{e.message}")
  end

  def remove_deleted_releases(artist_record, releases_on_disk, matched_release_ids = [])
    artist_record.releases.each do |release|
      next if matched_release_ids.include?(release.id)

      releases_on_disk.values.each do |release_path|
        if release.respond_to?(:path) && release.path.present? && release.path == release_path
          next
        end
      end

      release_path_on_disk = nil
      if release.respond_to?(:path) && release.path.present?
        release_path_on_disk = releases_on_disk.values.find { |p| p == release.path }
      end
      next if release_path_on_disk

      if releases_on_disk.key?(release.title)
        next
      end

      release.cover.purge if release.cover.attached?
      release.tracks.each { |track| track.audio_file.purge if track.audio_file.attached? }
      release.destroy
    end
  rescue StandardError => e
    Rails.logger.error("Failed to remove deleted releases for artist #{artist_record.title}: #{e.message}")
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
