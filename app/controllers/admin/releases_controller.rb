class Admin::ReleasesController < ApplicationController

  def show
    render turbo_stream: turbo_stream.update("admin_body", partial: "system")
  end

end
