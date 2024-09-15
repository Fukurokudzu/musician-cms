module ScanLibHelper
  def self.get_folders_list(path)
    folders_list = {}
    Dir.chdir(Pathname.new(path)) do
      Dir.glob('*').map do |folder|
        folders_list[folder] = File.absolute_path(folder) if File.directory?(folder)
      end
    end
    folders_list
  end

  def self.get_tracks_list(path)
    Dir.chdir(Pathname.new(path)) do
      Dir.glob(track_pattern).each_with_object({}) do |file, tracks|
        tracks[file] = File.absolute_path(file)
      end
    end
  end

  def self.get_release_cover(path)
    Dir.chdir(Pathname.new(path)) do
      cover_file = Dir.glob(cover_pattern).first
      File.absolute_path(cover_file) if cover_file
    end
  end

  private

  def self.cover_pattern
    cover_filenames = Setting.cover_filenames
    cover_extensions = Setting.cover_extensions

    cover_filenames.map! { |filename| filename.downcase + '*' }
    cover_filenames += cover_filenames.map { |filename| add_capital_letters(filename) }
    cover_filenames += cover_filenames.map { |filename| filename.upcase }

    cover_extensions += cover_extensions.map { |extension| add_capital_letters(extension) }
    cover_extensions += cover_extensions.map { |extension| extension.upcase }

    "{#{cover_filenames.join(',')}}.{#{cover_extensions.join(',')}}"
  end

  def self.track_pattern
    "*.{#{Setting.track_extensions.join(',')}}"
  end

  def self.add_capital_letters(string)
    string.capitalize
  end
end
