class ReleasesController < ApplicationController
  def index
  end

  def show
    @release = Release.find_by(external_id: params[:id]) || Release.find_by(id: params[:id])
    @tracks = @release&.tracks
  end
end
