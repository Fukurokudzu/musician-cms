class ThemesController < ApplicationController
  DEFAULT_BACKGROUND = 'korg.jpg'.freeze

  def variables
    theme_fields = Setting.defined_fields
                          .reject { |field| field[:readonly] || field[:key].to_s == 'background_image' }
                          .group_by { |field| field[:scope] }[:theme] || []

    css = ":root {\n"
    theme_fields.each do |field|
      css += "  --#{field[:key].to_s.dasherize}: #{Setting.send(field[:key])};\n"
    end
    css += "}\n"

    css += "body {\n  background-image: url(\"#{background_image_url}\");\n}\n"

    render inline: css, content_type: 'text/css'
  end

  private

  def background_image_url
    blob = ActiveStorage::Blob.find_signed(Setting.background_image.presence)
    blob ? view_context.url_for(blob) : view_context.asset_path(DEFAULT_BACKGROUND)
  end
end
