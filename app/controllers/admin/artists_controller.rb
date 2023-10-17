class Admin::ArtistsController < ApplicationController
  
  def show
    render turbo_stream: turbo_stream.update("admin_body", partial: "system")
  end

  def index
    @artists = Artist.all
  end

  def new
    @artist = Artist.new
    render turbo_stream: turbo_stream.update("admin_body", partial: "new")
  end

end
