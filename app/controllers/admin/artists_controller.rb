class Admin::ArtistsController < ArtistsController
  include AdminAuthorization

  before_action :set_artist, only: [:show, :edit, :update, :destroy]
  before_action :set_all_artists, only: [:index, :create, :destroy]

  def new
    @artist = Artist.new
    render turbo_stream: turbo_stream.update('admin_body', partial: 'new')
  end

  def show
    render turbo_stream: turbo_stream.update('admin_body', partial: 'edit')
  end

  def edit
    render turbo_stream: turbo_stream.update('admin_body', partial: 'edit')
  end

  def create
    @artist = Artist.new(check_params)
    if @artist.save
      @artists = Artist.all.active
      flash.now[:success] = 'Artist was successfully created.'
      render turbo_stream: turbo_stream.update('admin_body', partial: 'index')
    else
      show_flash(:error, 'Could not create artist')
    end
  end

  def index
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.update('admin_body', partial: 'index') }
      format.html { redirect_to admin_path }
    end
  end

  def update
    if @artist.update(check_params)
      @artists = Artist.all.active.order(:title)
      flash.now[:success] = t('settings.update', default: 'Updated')
      render turbo_stream: [
        turbo_stream.update('admin_body', partial: 'index'),
        turbo_stream.update('flash', partial: 'layouts/flash')
      ]
    else
      flash.now[:error] = @artist.errors.full_messages.join(', ')
      render turbo_stream: [
        turbo_stream.update('admin_body', partial: 'edit'),
        turbo_stream.update('flash', partial: 'layouts/flash')
      ], status: :unprocessable_entity
    end
  end

  def destroy
    if @artist.update(soft_deleted: true)
      @artists = Artist.all.active.order(:title)
      flash.now[:success] = t('settings.delete', default: 'Deleted')
      render turbo_stream: [
        turbo_stream.update('admin_body', partial: 'index'),
        turbo_stream.update('flash', partial: 'layouts/flash')
      ]
    else
      show_flash(:error, 'Could not destroy artist')
    end
  end

  private

  def set_artist
    @artist = find_artist
  end

  def set_all_artists
    @artists = Artist.all.active
  end
end
