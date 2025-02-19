class PlayerController < ApplicationController
  def show
    @track = params[:id] ? Track.find(params[:id]) : Track.all.sample
    @release = @track.release
  end

  def update_track
    @track = Track.find(params[:id]) || session_track
    @release = @track.release

    update_session_track_id
    present_track
  end

  def next_track
    @track = select_track(current_track: session_track)
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

  def update_session_track_id
    session[:current_track_id] = @track.id
  end

  def session_track
    session[:current_track_id] ? Track.find(session[:current_track_id]) : Track.all.sample
  end

  def present_track
    respond_to do |format|
      format.json do
        render json: { release_url: url_for(@release),
                       track_audio_url: url_for(@track.audio_file),
                       status: :ok }
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
    tracks(current_track).where(pos_query, current_track.pos).first ||
      tracks(current_track).where(id_query, current_track.id).first
  end

  def random_track
    Track.all.sample
  end

  def tracks(current_track)
    current_track.release.tracks
  end
end
