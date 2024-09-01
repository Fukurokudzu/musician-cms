module ScanLibHelper
  def get_folders_list(path)
    folders_list = {}
    Dir.chdir(Pathname.new(path)) do
      Dir.glob('*').map do |folder|
        folders_list[folder] = File.absolute_path(folder) if File.directory?(folder)
      end
    end
    folders_list
  end

  def get_tracks_list(path)
    Dir.chdir(Pathname.new(path)) do
      Dir.glob(track_pattern).each_with_object({}) do |file, tracks|
        tracks[file] = File.absolute_path(file)
      end
    end
  end

  def get_release_cover(path)
    Dir.chdir(Pathname.new(path)) do
      Dir.glob(cover_pattern).each_with_object({}) do |file, covers|
        covers[file] = File.absolute_path(file)
      end
    end
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