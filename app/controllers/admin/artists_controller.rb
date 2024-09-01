class Admin::ArtistsController < ArtistsController

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
      render turbo_stream: turbo_stream.update("admin_body", partial: "index")
    else
      render turbo_stream: turbo_stream.update("admin_body", partial: "index")
    end
  end

  def index
    @artists = Artist.all
    render turbo_stream: turbo_stream.update("admin_body", partial: "index")
  end

  def destroy
    @artist = Artist.find(params[:id])
    @artist.destroy
    render turbo_stream: turbo_stream.update("admin_body", partial: "index")
  end

end
