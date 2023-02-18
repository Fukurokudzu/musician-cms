require_relative('scan_lib_helper')
require('wahwah')

class ScanLibJob < ApplicationJob
  queue_as :default
  
  include ScanLibHelper

  def perform(artist_title)

    p "======================= JOB ======================"
    releases = ScanLibHelper.get_releases_list(artist_title)
    releases.each do |release_path|
      tracks = ScanLibHelper.get_tracks_list(release_path)
      tracks.each do |track_path|
        tag = WahWah.open(track_path)
      end
    end

  end


end
