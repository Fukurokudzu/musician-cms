module ThemeHelper
  DEFAULT_BACKGROUND = 'korg.jpg'.freeze
  COLOR_PATTERN = /\A#(?:[0-9a-fA-F]{3}|[0-9a-fA-F]{4}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})\z/
  MAX_BORDER_RADIUS = 50

  THEME_COLOR_KEYS = %i[
    artist_title_color
    text_color
    main_menu_bg_color
    footer_bg_color
    player_bg_color
    accent_color
    a_color
    a_hover_color
  ].freeze

  # Inline theme overrides are part of the HTML page, so they need no separate
  # request and cannot go stale between saves.
  def theme_style_tag
    # Values are sanitized above (allow-listed colors, clamped radius, Rails-built
    # URL), so the generated CSS can be emitted without HTML escaping: quotes
    # inside url("...") must stay literal, otherwise the rule is invalid.
    tag.style(theme_css.html_safe, nonce: content_security_policy_nonce)
  end

  private

  def theme_css
    variables = THEME_COLOR_KEYS.map do |key|
      "  --#{key.to_s.dasherize}: #{safe_color(Setting.public_send(key))};"
    end
    variables << "  --border-radius: #{theme_border_radius}px;"

    <<~CSS
      :root {
      #{variables.join("\n")}
      }

      body {
        background-image: url("#{theme_background_url}");
      }
    CSS
  end

  def safe_color(value)
    value.to_s[COLOR_PATTERN] || '#ffffff'
  end

  def theme_border_radius
    [[Setting.border_radius.to_i, 0].max, MAX_BORDER_RADIUS].min
  end

  def theme_background_url
    blob = ActiveStorage::Blob.find_signed(Setting.background_image.presence)

    blob ? url_for(blob) : asset_path(DEFAULT_BACKGROUND)
  rescue ActiveRecord::RecordNotFound, ActiveSupport::MessageVerifier::InvalidSignature
    asset_path(DEFAULT_BACKGROUND)
  end
end
