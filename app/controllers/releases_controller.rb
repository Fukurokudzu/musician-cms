class ReleasesController < ApplicationController
  def index
  end

  def show
    @release = Release.find(params[:id])
  end
end
