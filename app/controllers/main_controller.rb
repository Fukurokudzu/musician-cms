class MainController < ApplicationController
  def index
    @artists = Artist.includes(:releases).all.order('releases.release_date DESC')
  end
end
