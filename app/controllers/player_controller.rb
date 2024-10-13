class PlayerController < ApplicationController
  def show
    @track = params[:id] ? Track.find(params[:id]) : Track.all.sample
    @release = @track.release
  end

  def update_track
    @track = Track.find(params[:id])
    @release = @track.release

    Rails.cache.write('current_track_id', @track.id)

    respond_to do |format|
      format.json { render json: { release_url: url_for(@release) } }
    end
  end
end
