class ReleasesController < ApplicationController
  def index
  end

  def show
    @release = Release.find(params[:id])
    @tracks = @release.tracks
  end
end
