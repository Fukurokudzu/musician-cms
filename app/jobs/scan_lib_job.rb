require_relative('../services/library')
require_relative('../services/artist_manager')
require_relative('../services/release_manager')
require_relative('scan_lib_helper')
require('wahwah')

class ScanLibJob < ApplicationJob
  queue_as :default

  include ScanLibHelper

  def perform
    p "======================= JOB ======================"

    library = Library.new(File.join(Rails.root, Setting.library_path))
    artist_manager = ArtistManager.new(library.artist_folders)
    release_manager = ReleaseManager.new(library.artist_folders)

    artist_manager.create_artists
    release_manager.update_releases
  end
end