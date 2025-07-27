class Admin::ArtistsController < ArtistsController
  before_action :set_all_artists, only: [:index, :create, :destroy]

  def new
    @artist = Artist.new
    render turbo_stream: turbo_stream.update('admin_body', partial: 'new')
  end

  def show
    @artist = Artist.find(params[:id])
  end

  def create
    @artist = Artist.new(check_params)
    if @artist.save
      @artists = Artist.all.active
      flash[:notice] = 'Artist was successfully created.'
      render turbo_stream: turbo_stream.update('admin_body', partial: 'index')
    else
      show_flash(:error, 'Could not create artist')
    end

  end

  def index
    render turbo_stream: turbo_stream.update('admin_body', partial: 'index')
  end

  def destroy
    @artist = Artist.find(params[:id])
    if @artist.update(soft_deleted: true)
      set_all_artists
      redirect_to admin_path, notice: 'Artist was successfully destroyed.'
    else
      show_flash(:error, 'Could not destroy artist')
    end
  end

  private

  def set_all_artists
    @artists = Artist.all.active
  end

end
