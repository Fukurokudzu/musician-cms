class Admin::ArtistsController < ArtistsController

  before_action :set_all_artists, only: [:index, :create, :destroy]

  def new
    @artist = Artist.new
    render turbo_stream: turbo_stream.update("admin_body", partial: "new")
  end

  def show
    @artist = Artist.find(params[:id])
  end

  def create
    @artist = Artist.new(check_params)
    if @artist.save
      @artists = Artist.all
      render turbo_stream: turbo_stream.update("admin_body", partial: "index")
    else
      render turbo_stream: turbo_stream.update("admin_body", partial: "index")
    end
  end

  def index
    render turbo_stream: turbo_stream.update("admin_body", partial: "index")
  end

  def destroy
    @artist = Artist.find(params[:id])
    if @artist.destroy
      render turbo_stream: turbo_stream.update("admin_body", partial: "index")
    end
  end

  private

  def set_all_artists
    @artists = Artist.all
  end

end
