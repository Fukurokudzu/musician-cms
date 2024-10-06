class TracksController < ApplicationController
  def index
    @tracks = Track.all
    @track = @tracks.first
  end

  def show
    @track = Track.find(params[:id])
    @release = @track.release
  end
end
