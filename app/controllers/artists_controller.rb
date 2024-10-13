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
    @artists = Artist.all
  end

  def update
    @artist = Artist.find(params[:id])
    return unless @artist.update(check_params)

    show_flash(:success, 'Artist updated successfully')
  end

  def show
    @artist = Artist.find(params[:id])
    return if @artist.description.nil?

    options = {
      auto_ids: true,
      footnote_nr: 1,
      entity_output: :as_char,
      toc_levels: (1..6),
      smart_quotes: ['lsquo', 'rsquo', 'ldquo', 'rdquo'],
      input: 'GFM', # GitHub Flavored Markdown
      hard_wrap: false,
      enable_coderay: true,
      coderay_line_numbers: nil,
      coderay_css: :style,
      coderay_bold_every: 10,
      coderay_tab_width: 4
    }

    @md_description = Kramdown::Document.new(@artist.description, options).to_html.html_safe

  end

  private

  def check_params
    params.require(:artist).permit(:title, :first_name, :last_name, :role, :description)
  end
end
