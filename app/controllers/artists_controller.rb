class ArtistsController < ApplicationController
  # Only public reading actions live here. Everything that changes data is
  # implemented in Admin::ArtistsController behind the admin session check.
  def show
    lookup = find_short_codeable!(public_scope: Artist.active, param: params[:id])
    @artist = Artist.includes(releases: { cover_attachment: { blob: :variant_records } })
                    .find(lookup.id)
    @md_description = MarkdownRenderer.call(@artist.description) if @artist.description.present?
  end
end
