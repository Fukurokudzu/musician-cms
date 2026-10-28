class PlayerController < ApplicationController
  def show
    @track = Track.find_by(external_id: params[:id]) || Track.find_by(id: params[:id]) || session_track || random_track
    process_track
  end

  def next_track
    @track = select_track(current_track: session_track, direction: :next)
    process_track
  end

  def previous_track
    @track = select_track(current_track: session_track, direction: :prev)
    process_track
  end

  private

  def process_track
    @release = @track.release
    update_session_track_id
    present_track
    @track.increment_plays!
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
    return random_track if invalid_direction?(direction) || single_track?(current_track)

    find_next_or_previous_track(current_track, direction) || tracks(current_track).first
  end

  def invalid_direction?(direction)
    %i[next prev].exclude?(direction)
  end

  def single_track?(current_track)
    current_track.release.tracks.count <= 1
  end

  def tracks(current_track)
    current_track.release.tracks
  end

  def find_next_or_previous_track(current_track, direction)
    track_list = tracks(current_track).order(Arel.sql('COALESCE(pos, 0) ASC'), :id).to_a
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

  def sort_tracks_by_direction(current_track, direction)
    tracks_collection = tracks(current_track)
    return tracks_collection.order(pos: :asc, id: :asc) if direction == :next

    tracks_collection.order(pos: :desc, id: :desc)
  end

  def find_track_index(tracks, current_track)
    tracks.index { |track| track.id == current_track.id }
  end

  def calculate_next_index(current_index, total_length, direction)
    next_index = direction == :next ? current_index + 1 : current_index - 1
    return nil if next_index.negative? || next_index >= total_length

    next_index
  end
end
