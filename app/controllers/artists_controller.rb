class ArtistsController < ApplicationController

  def new
    @artist = Artist.new
  end

  def create
    @artist = Artist.new(check_params)
    if @artist.save
      render(root_path)
    else
      render(root_path)
    end
  end

  def show
  end

  private

  def check_params
    params.require(:artist).permit(:title)
  end
end
