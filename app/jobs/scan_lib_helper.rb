module ScanLibHelper
  
  def self.get_releases_list(artist_title)
    releases = []
    Dir.chdir(Rails.root.join('app', 'music', artist_title)) do
      Dir.glob('*').map do |folder|
        releases << File.absolute_path(folder) if File.directory?(folder)
      end
    end
    releases
  end

  def self.get_tracks_list(release_path)
    tracks = []
    Dir.chdir(release_path) do
      Dir.glob('*.{mp3').map do |file|
        tracks << File.absolute_path(file)
      end
    end
    tracks
  end

  def self.get_release_cover(release_path)
    cover_filenames = Setting.cover_filenames.split(" ").join(",")
    Dir.chdir(release_path)
    Dir.glob("{#{cover_filenames}}.{jpg,jpeg,png}")
  end
end