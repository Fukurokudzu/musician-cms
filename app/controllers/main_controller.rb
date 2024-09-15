class MainController < ApplicationController
  def index
    @artists = Artist.includes(:releases).all
  end
end
