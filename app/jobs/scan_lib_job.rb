require_relative('scan_lib_helper')
require('wahwah')

class ScanLibJob < ApplicationJob
  queue_as :default
  
  include ScanLibHelper

  def perform(artist_title)

    p "======================= JOB ======================"

    library_path = Rails.root.join(Setting.library_path)
    artists = get_folders_list(library_path)

    artists.each_pair do |artist, artist_path|
      releases = get_folders_list(artist_path)

      releases.each_pair do |release, release_path|
        tracks = get_tracks_list(release_path)
        #REMOVE later
        # tracks.each_pair do |track, track_path|
        #   tag = WahWah.open(track_path)
        #   p tag.title unless tag.title.nil? 
        # end
        covers = get_release_cover(release_path)
      end
    end

  end


end
