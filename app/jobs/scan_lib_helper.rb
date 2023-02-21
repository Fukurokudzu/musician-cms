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
      Dir.glob('*.{mp3}').map do |file|
        tracks[file] = File.absolute_path(file)
      end
    end
    tracks
  end

  def get_release_cover(path)
    path = Pathname.new(path)
    covers = {}
    cover_filenames = Setting.cover_filenames.split(" ").join(",")
    Dir.chdir(path)
    Dir.glob("{#{cover_filenames}}.{jpg,jpeg,png}").map do |file|
      covers[file] = File.absolute_path(file)
    end
    covers
  end
end