module ScanLibHelper

  def get_folders_list(path)
    folders_list = {}
    path = Pathname.new(path)
    Dir.chdir(path) do
      Dir.glob('*').map do |folder|
        folders_list[folder] = File.absolute_path(folder) if File.directory?(folder)
      end
    end
    folders_list
  end

  def get_tracks_list(path)
    path = Pathname.new(path)
    tracks = {}
    Dir.chdir(path) do
      Dir.glob(track_pattern).map do |file|
        tracks[file] = File.absolute_path(file)
      end
    end
    tracks
  end

  def get_release_cover(path)
    path = Pathname.new(path)
    covers = {}
    Dir.chdir(path)
    Dir.glob(cover_pattern).map do |file|
      covers[file] = File.absolute_path(file)
    end
    covers
  end

  private

  def cover_pattern
    cover_filenames = Setting.cover_filenames.join(',')
    "{#{cover_filenames}}.{#{Setting.cover_extensions.join(',')}}"
  end

  def track_pattern
    "*.{#{Setting.track_extensions.join(',')}}"
  end
end
