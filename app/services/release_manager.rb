class ReleaseManager
  def initialize(artist_folders)
    @artist_folders = artist_folders
  end

  def update_releases
    @artist_folders.each_pair do |artist, artist_path|
      releases = get_folders_list(artist_path)
      releases.each_pair do |release, release_path|
        tracks = get_tracks_list(release_path)
        tags = get_tags(tracks)
        cover = get_release_cover(release_path)

        update_release(artist, release, tracks, tags, cover)
        update_tracks(artist, release, tracks, tags)
      end
    end
  end

  private

  def get_folders_list(path)
    ScanLibHelper.get_folders_list(path)
  end

  def get_tracks_list(path)
    ScanLibHelper.get_tracks_list(path)
  end

  def get_tags(tracks)
    tracks.each_with_object({}) do |(track, track_path), tags|
      tags[track] = WahWah.open(track_path).title
    end
  end

  def get_release_cover(path)
    ScanLibHelper.get_release_cover(path)
  end

  def update_release(artist, release, tracks, tags, cover)
    artist = Artist.find_by(title: artist)
    release = artist.releases.find_or_create_by(title: release)
    release.update!(tracks: update_tracks(artist, release, tracks, tags), cover: cover)
  end

  def update_tracks(artist, release, tracks, tags)
    artist = Artist.find_by(title: artist)
    release = artist.releases.find_or_create_by(title: release)
    tracks.each do |track, _|
      track_title = tags[track] || track
      release.tracks.find_or_create_by(title: track_title)
    end
  end
end