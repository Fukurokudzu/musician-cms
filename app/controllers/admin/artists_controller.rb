module Admin
  class ArtistsController < ApplicationController
    include AdminAuthorization

    before_action :set_artist, only: %i[show edit update destroy]
    before_action :set_all_artists, only: %i[index create destroy]

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
        AuditLogger.log(action: 'artist.created', target: @artist, request:,
                        metadata: { title: @artist.title })
        flash.now[:success] = 'Artist was successfully created.'
        render turbo_stream: turbo_stream.update('admin_body', partial: 'index')
      else
        show_flash('Could not create artist', type: :error)
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
        AuditLogger.log(action: 'artist.updated', target: @artist, request:,
                        metadata: { title: @artist.title, changes: check_params.keys })
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
        AuditLogger.log(action: 'artist.deleted', target: @artist, request:,
                        metadata: { title: @artist.title })
        flash.now[:success] = t('settings.delete', default: 'Deleted')
        render turbo_stream: [
          turbo_stream.update('admin_body', partial: 'index'),
          turbo_stream.update('flash', partial: 'layouts/flash')
        ]
      else
        show_flash('Could not destroy artist', type: :error)
      end
    end

    private

    def set_artist
      @artist = find_artist
    end

    def set_all_artists
      @artists = Artist.all.active
    end

    def find_artist
      find_short_codeable!(public_scope: Artist, param: params[:id])
    end

    def check_params
      params.require(:artist).permit(:title, :first_name, :last_name, :role, :description)
    end
  end
end
