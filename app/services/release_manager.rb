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
    tracks.each_with_object({}) do |(track, track_path), tags|
      tags[track] = WahWah.open(track_path).title
    end
  end

  def update_release(artist, release, tracks, tags, cover)
    artist_record = Artist.find_by!(title: artist)
    release_record = artist_record.releases.find_or_create_by(title: release)
    release_record.update!(cover: cover)
    update_tracks(release_record, tracks, tags)
  end

  def update_tracks(release, tracks, tags)
    tracks.each do |track, _|
      track_title = tags[track] || track
      release.tracks.find_or_create_by(title: track_title)
    end
  end
end
