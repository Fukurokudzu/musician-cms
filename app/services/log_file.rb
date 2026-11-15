# Metadata about the current environment's Rails log file for the admin
# panel's "Application log" section. The file itself is served via
# Admin::LogsController#download — never rendered into the page.
class LogFile
  TAIL_BYTES = 5 * 1024 * 1024

  Result = Struct.new(:path, :exists, :file_size, :mtime, keyword_init: true)

  def self.info
    new(Rails.root.join('log', "#{Rails.env}.log")).info
  end

  def initialize(path)
    @path = path
  end

  def info
    return Result.new(path: @path, exists: false, file_size: 0) unless File.exist?(@path)

    Result.new(path: @path, exists: true, file_size: File.size(@path), mtime: File.mtime(@path))
  rescue StandardError => e
    Rails.logger.error("LogFile info failed: #{e.class}: #{e.message}")
    Result.new(path: @path, exists: false, file_size: 0)
  end
end
