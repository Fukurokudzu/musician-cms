class Admin::LibrariesController < ApplicationController

  def show
    render turbo_stream: turbo_stream.update("admin_body", partial: "system")
  end

  def update
    # FIXME: artist = Artist.find(params[:id])
    artist = Artist.first
    ScanLibJob.perform_later(artist.title)
    flash.now[:success] = "Scan job started..."
    render turbo_stream: turbo_stream.update("flash", partial: "layouts/flash")
  end

end
