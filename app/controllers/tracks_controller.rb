class TracksController < ApplicationController
  def show
    lookup = begin
      find_short_codeable!(public_scope: Track.playable, param: params[:id])
    rescue ActiveRecord::RecordNotFound
      nil
    end
    return head :not_found unless lookup
    @track = Track.includes(release: [:artist]).find(lookup.id)
    @release = @track.release

    render json: {
      track: track_json(@track),
      release_tracks: @release.tracks.published.by_position.includes(audio_file_attachment: :blob)
                                    .to_a
                                    .select { |track| track.audio_file.attached? }
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
