module ScanLibHelper
  def self.get_folders_list(path)
    folders_list = {}
    Pathname.new(path).children.select(&:directory?).each do |child|
      folder_name = child.basename.to_s
      folders_list[folder_name] = child.expand_path.to_s
    end
    folders_list
  end

  def self.get_tracks_list(path)
    Dir.glob(File.join(path, track_pattern)).each_with_object({}) do |file, tracks|
      tracks[File.basename(file)] = File.expand_path(file)
    end
  end

  def self.get_release_cover(path)
    cover_file = Dir.glob(File.join(path, cover_pattern)).first
    return nil unless cover_file

    File.expand_path(cover_file)
  end

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
