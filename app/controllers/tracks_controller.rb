class TracksController < ApplicationController
  def show
    # Same rule as the player: only published releases with attached audio are
    # exposed, everything else answers 404 instead of leaking or raising.
    @track = Track.playable.find_by(external_id: params[:id]) ||
             Track.playable.find_by(id: params[:id])
    return head :not_found unless @track

    @release = @track.release
    release_tracks = @release.tracks.published.by_position.includes(:audio_file_attachment)

    render json: {
      track: track_json(@track),
      release_tracks: release_tracks.select { |track| track.audio_file.attached? }
                                    .map { |track| track_json(track) }
    }
  end

  private

  def track_json(track)
    {
      id: track.id,
      external_id: track.external_id,
      data_src: url_for(track.audio_file),
      artist: track.artists.first,
      title: track.title
    }
  end
end
