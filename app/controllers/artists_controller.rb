class ArtistsController < ApplicationController
  # Only public reading actions live here. Everything that changes data is
  # implemented in Admin::ArtistsController behind the admin session check.
  def show
    @artist = Artist.includes(releases: { cover_attachment: { blob: :variant_records } })
                    .find_by!(external_id: params[:id])
    @md_description = MarkdownRenderer.call(@artist.description) if @artist.description.present?
  rescue ActiveRecord::RecordNotFound
    @artist = Artist.includes(releases: { cover_attachment: { blob: :variant_records } }).find(params[:id])
    @md_description = MarkdownRenderer.call(@artist.description) if @artist.description.present?
  end
end
