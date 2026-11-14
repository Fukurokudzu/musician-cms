class MainController < ApplicationController
  def index
    @artists = Artist.active
                     .includes(releases: { cover_attachment: { blob: :variant_records } })
                     .order(:title)
  end
end
