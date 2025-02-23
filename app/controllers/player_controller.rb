class PlayerController < ApplicationController
  def show
    @track = Track.find(params[:id]) || session_track || random_track
    @release = @track.release

    update_session_track_id
    present_track
  end

  def next_track
    @track = select_track(current_track: session_track, direction: :next)
    @release = @track.release

    update_session_track_id
    present_track
  end

  def previous_track
    @track = select_track(current_track: session_track, direction: :prev)
    @release = @track.release

    update_session_track_id
    present_track
  end

  private

  def present_track
    respond_to do |format|
      format.json do
        render json: {
          track: {
            data_src: url_for(@track.audio_file),
            artist: @track.release.artist.title,
            title: @track.title,
            id: @track.id
          },
          status: :ok
        }
      end
    end
  end

  def select_track(current_track:, direction: :next)
    return random_track if invalid_direction?(direction) || single_track?(current_track)

    find_next_or_previous_track(current_track, direction) || tracks(current_track).first
  end

  def invalid_direction?(direction)
    %i[next prev].exclude?(direction)
  end

  def single_track?(current_track)
    current_track.release.tracks.count <= 1
  end

  def find_next_or_previous_track(current_track, direction)
    pos_query = direction == :next ? 'pos > ?' : 'pos < ?'
    id_query = direction == :next ? 'id > ?' : 'id < ?'
    order_direction = direction == :next ? 'asc' : 'desc'

    tracks(current_track)
      .where(pos_query, current_track.pos)
      .order(pos: order_direction)
      .first ||
      tracks(current_track)
        .where(id_query, current_track.id)
        .order(id: order_direction)
        .first
  end

  def tracks(current_track)
    current_track.release.tracks
  end
end
