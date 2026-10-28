module ScanLibHelper
  def self.get_folders_list(path)
    folders_list = {}
    Pathname.new(path).children.select(&:directory?).each do |child|
      folder_name = child.basename.to_s
      next if folder_name.start_with?('.')

      folders_list[folder_name] = child.expand_path.to_s
    end
    folders_list
  end

  def self.get_tracks_list(path)
    extensions = Setting.track_extensions.map { |ext| ext.downcase.delete_prefix('.') }

    Dir.children(path).each_with_object({}) do |entry, tracks|
      next if entry.start_with?('.')

      full_path = File.join(path, entry)
      next unless File.file?(full_path)
      next unless extensions.include?(File.extname(entry).delete_prefix('.').downcase)

      tracks[entry] = File.expand_path(full_path)
    end
  end

  def self.get_release_cover(path)
    filenames = Setting.cover_filenames.map(&:downcase)
    extensions = Setting.cover_extensions.map { |ext| ext.downcase.delete_prefix('.') }

    cover_file = Dir.children(path).sort.find do |entry|
      next if entry.start_with?('.')

      full_path = File.join(path, entry)
      next unless File.file?(full_path)

      extension = File.extname(entry).delete_prefix('.').downcase
      basename = File.basename(entry, File.extname(entry)).downcase

      extensions.include?(extension) && filenames.any? { |name| basename.start_with?(name) }
    end

    cover_file && File.expand_path(File.join(path, cover_file))
  end
end
