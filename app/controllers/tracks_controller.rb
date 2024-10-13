class TracksController < ApplicationController
  def index
    @tracks = Track.all
    @track = @tracks.first
  end

  def show
    @track = Track.find(params[:id])
    @release = @track.release
    @release_tracks = @release.tracks

    render json: {
      track: {
        id: @track.id,
        data_src: url_for(@track.audio_file),
        artist: @track.artists.first,
        title: @track.title
      },
      release_tracks: @release_tracks.map { |t|
        {
          id: t.id,
          data_src: url_for(t.audio_file),
          artist: t.artists.first,
          title: t.title
        }
      }
    }
  end
end
