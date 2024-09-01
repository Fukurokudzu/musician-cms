class Admin::LibrariesController < ApplicationController

  def show
    render turbo_stream: turbo_stream.update("admin_body", partial: "system")
  end

  def update
    # FIXME: artist = Artist.find(params[:id])
    ScanLibJob.perform_later
    flash.now[:success] = "Scan job started..."
    render turbo_stream: turbo_stream.update("flash", partial: "layouts/flash")
  end

end
