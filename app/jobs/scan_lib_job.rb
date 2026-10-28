require_relative('../services/library')
require_relative('../services/artist_manager')
require_relative('../services/release_manager')
require_relative('scan_lib_helper')
require('wahwah')

class ScanLibJob < ApplicationJob
  queue_as :default

  include ScanLibHelper

  def perform
    Rails.logger.info "ScanLibHelper JOB STARTED"
    @success = false

    library_path = Setting.library_path
    library_path = File.join(Rails.root, library_path) unless Pathname.new(library_path).absolute?
    Rails.logger.info "Scanning library at: #{library_path}"

    # Check if directory exists
    unless Dir.exist?(library_path)
      Rails.logger.error "Library path not found: #{library_path}"
      return self
    end

    library = Library.new(library_path)
    artist_manager = ArtistManager.new(library.artist_folders)
    release_manager = ReleaseManager.new(library.artist_folders)

    artist_manager.create_artists
    release_manager.update_releases

    Rails.logger.info "ScanLibHelper JOB COMPLETED"
    @success = true

    self
  rescue StandardError => e
    Rails.logger.error "ScanLibJob failed: #{e.class}: #{e.message}"
    Rails.logger.error e.backtrace.first(20).join("\n")
    @success = false
    self
  end

  def success?
    @success
  end
end
