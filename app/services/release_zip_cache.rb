# Keeps a ready-made ZIP attached to the release so repeated downloads do not
# rebuild the archive from every audio blob on every request.
#
# Freshness is decided by Release#zip_archive_fresh?, which compares a digest
# of everything that affects the archive with the version embedded in the
# stored filename. No manual invalidation in controllers or jobs is needed.
class ReleaseZipCache
  def initialize(release)
    @release = release
  end

  # Returns the attached blob, rebuilding it first when it is stale.
  def blob
    return @blob if defined?(@blob)

    @blob = if @release.zip_archive_fresh?
              @release.zip_archive.blob
            else
              rebuild
            end
  end

  private

  def rebuild
    builder = ReleaseZipBuilder.new(@release)
    @release.zip_archive.attach(
      io: StringIO.new(builder.call),
      filename: "#{@release.zip_version}--#{builder.filename}",
      content_type: 'application/zip'
    )
    @release.zip_archive.blob
  end
end
