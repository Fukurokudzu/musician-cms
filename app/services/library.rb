class Library
  attr_reader :path, :artist_folders

  include ScanLibHelper

  def initialize(path)
    @path = path
    @artist_folders = get_artist_folders
  end

  private

  def get_artist_folders
    raise("Library #{path} path not found") unless Dir.exist?(path)
    folders = ScanLibHelper.get_folders_list(path)
    raise("No artist folders found in #{path}") if folders.empty?
    folders
  end
end
