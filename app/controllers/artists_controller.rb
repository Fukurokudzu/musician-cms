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

  def index
    @artists = Artist.all
  end

  private

  def check_params
    params.require(:artist).permit(:title, :first_name, :last_name, :role)
  end
end
