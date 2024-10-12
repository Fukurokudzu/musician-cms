class ThemesController < ApplicationController
  def variables
    theme_fields = Setting.defined_fields
                          .reject { |field| field[:readonly] }
                          .group_by { |field| field[:scope] }[:theme] || []

    css = ":root {\n"
    theme_fields.each do |field|
      css += "  --#{field[:key].to_s.dasherize}: #{Setting.send(field[:key])};\n"
    end
    css += "}\n"
    render inline: css, content_type: 'text/css'
  end
end
