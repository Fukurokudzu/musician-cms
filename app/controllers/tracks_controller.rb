class TracksController < ApplicationController
  def index
    @tracks = Track.all
    @track = @tracks.first
  end

  def show
    @track = Track.find_by(external_id: params[:id]) || Track.find_by(id: params[:id])
    return head :not_found unless @track
    @release = @track.release
    @release_tracks = @release.tracks.order(Arel.sql('COALESCE(pos, 0) ASC'), :id)

    render json: {
      track: {
        id: @track.id,
        external_id: @track.external_id,
        data_src: url_for(@track.audio_file),
        artist: @track.artists.first,
        title: @track.title
      },
      release_tracks: @release_tracks.map { |t|
        {
          id: t.id,
          external_id: t.external_id,
          data_src: url_for(t.audio_file),
          artist: t.artists.first,
          title: t.title
        }
      }
    }
  end
end
