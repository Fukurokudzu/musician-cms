class PlayerController < ApplicationController
  def show
    @track = resolve_playable_track || active_track
    return render_no_tracks unless @track

    process_track
  end

  def next_track
    @track = select_track(current_track: session_track, direction: :next)
    return render_no_tracks unless @track

    process_track
  end

  def previous_track
    @track = select_track(current_track: session_track, direction: :prev)
    return render_no_tracks unless @track

    process_track
  end

  private

  def resolve_playable_track
    lookup = find_short_codeable!(public_scope: Track.playable, param: params[:id])
    Track.playable.find(lookup.id)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def render_no_tracks
    render json: { error: 'No tracks available' }, status: :not_found
  end

  def process_track
    @release = @track.release
    update_session_track_id
    present_track
    StatTracker.record_play(track: @track, request: request)
  end

  def present_track
    respond_to do |format|
      format.json do
        render json: {
          track: {
            data_src: url_for(@track.audio_file),
            artist: @track.release.artist.title,
            title: @track.title,
            id: @track.id,
            external_id: @track.external_id
          },
          status: :ok
        }
      end
    end
  end

  def select_track(current_track:, direction: :next)
    return random_track if current_track.nil? || invalid_direction?(direction) || single_track?(current_track)

    track = find_next_or_previous_track(current_track, direction)
    return track if track

    # Wrap to the first track of the release only when moving forward;
    # when moving backward from the first track we stay on the current one.
    direction == :next ? ordered_tracks(current_track).first : current_track
  end

  def invalid_direction?(direction)
    %i[next prev].exclude?(direction)
  end

  def single_track?(current_track)
    current_track.release.tracks.published.count <= 1
  end

  def tracks(current_track)
    current_track.release.tracks.published
  end

  def ordered_tracks(current_track)
    tracks(current_track).by_position
  end

  def find_next_or_previous_track(current_track, direction)
    track_list = ordered_tracks(current_track).to_a
    current_index = track_list.index { |track| track.id == current_track.id }
    return nil unless current_index

    if direction == :next
      next_index = current_index + 1
      return track_list[next_index] if next_index < track_list.length
    else
      prev_index = current_index - 1
      return track_list[prev_index] if prev_index >= 0
    end

    nil
  end
end
