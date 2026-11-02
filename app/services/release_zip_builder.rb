# Packs a release (cover + all attached tracks) into a single ZIP archive.
#
# Entries are stored without compression (Zip::Entry::STORED): audio files and
# images are already compressed, so deflating them would only waste CPU time.
class ReleaseZipBuilder
  CHUNK_SIZE = 1.megabyte
  MAX_NAME_LENGTH = 120
  SAFE_EXTENSION = /\A\.[a-z0-9]{1,10}\z/

  def initialize(release)
    @release = release
    @used_names = Set.new
  end

  def call
    Zip::OutputStream.write_buffer do |zip|
      write_cover(zip)
      write_tracks(zip)
    end.string
  end

  def filename
    "#{sanitize(@release.title).presence || 'release'}.zip"
  end

  private

  def write_cover(zip)
    return unless @release.cover.attached?

    write_entry(zip, @release.cover, "cover#{extension(@release.cover)}")
  end

  def write_tracks(zip)
    tracks.each_with_index do |track, index|
      next unless track.audio_file.attached?

      number = track.pos || index + 1
      name = format('%02d %s%s', number, track_stem(track), extension(track.audio_file))
      write_entry(zip, track.audio_file, unique_name(name))
    end
  end

  # "01 Исполнитель - Название"
  def track_stem(track)
    artist = sanitize(@release.artist&.title)
    title = sanitize(track.title).presence || 'track'

    artist.present? ? "#{artist} - #{title}" : title
  end

  def write_entry(zip, attachment, entry_name)
    @used_names << entry_name
    zip.put_next_entry(entry_name, nil, nil, Zip::Entry::STORED)

    attachment.blob.open do |io|
      while (chunk = io.read(CHUNK_SIZE))
        zip.write(chunk)
      end
    end
  end

  def tracks
    @release.tracks.order(Arel.sql('COALESCE(pos, 999999)'), :id)
  end

  def unique_name(name)
    return name unless @used_names.include?(name)

    extension = File.extname(name)
    stem = name.delete_suffix(extension)
    suffix = 2
    suffix += 1 while @used_names.include?("#{stem} (#{suffix})#{extension}")

    "#{stem} (#{suffix})#{extension}"
  end

  def extension(attachment)
    ext = File.extname(attachment.filename.to_s).downcase
    ext.match?(SAFE_EXTENSION) ? ext : ''
  end

  def sanitize(name)
    name.to_s.gsub(%r{[/\\:*?"<>|\x00-\x1f]}, ' ').squish.truncate(MAX_NAME_LENGTH, omission: '')
  end
end
