class ArtistsController < ApplicationController

  def new
    @artist = Artist.new
  end

  def create
    @artist = Artist.new(check_params)
    if @artist.save
      render(root_path)
    else
      render(root_path)
    end
  end

  def index
    @artists = Artist.active
  end

  def update
    @artist = find_artist
    return unless @artist.update(check_params)

    show_flash(:success, 'Artist updated successfully')
  end

  def show
    @artist = find_artist
    return if @artist.description.nil?

    @md_description = MarkdownRenderer.call(@artist.description)
  end

  def destroy
    return unless admin?

    @artist = find_artist
    return unless @artist.update(soft_deleted: true)

    show_flash(:success, 'Artist deleted successfully')
  end

  private

  def find_artist
    Artist.find_by!(external_id: params[:id])
  rescue ActiveRecord::RecordNotFound
    Artist.find(params[:id])
  end

  def check_params
    params.require(:artist).permit(:title, :first_name, :last_name, :role, :description)
  end
end
