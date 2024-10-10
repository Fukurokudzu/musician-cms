# RailsSettings Model
class Setting < RailsSettings::Base
  cache_prefix { "v1" }

  # Define your fields
  # field :host, type: :string, default: "http://localhost:3000"
  # field :default_locale, default: "en", type: :string
  # field :confirmable_enable, default: "0", type: :boolean
  # field :admin_emails, default: "admin@rubyonrails.org", type: :array
  # field :omniauth_google_client_id, default: (ENV["OMNIAUTH_GOOGLE_CLIENT_ID"] || ""), type: :string, readonly: true
  # field :omniauth_google_client_secret, default: (ENV["OMNIAUTH_GOOGLE_CLIENT_SECRET"] || ""), type: :string, readonly: true

  scope :application do
    field :app_name, default: "Musician CMS", validates: { presence: true, length: { in: 2..30 } }
    field :host, default: "https://example.com"
    field :locale, default: "en", validates: { presence: true }, option_values: %w[en ru]
    field :timezone, default: ""
    field :cover_filenames, default: %w[cover artwork], validates: { presence: true }
    field :cover_extensions, default: %w[jpg jpeg png], validates: { presence: true }
    field :track_extensions, default: %w[mp3 wav wave], validates: { presence: true }
    field :email_pattern, default: ".*@.*", validates: { presence: true }
    field :library_path, default: "app/music", validates: { presence: true }
  end

  scope :admin do
    field :admin_email, default: "admin@admin", validates: { presence: true }
    field :admin_hashed_password, default: "$2a$12$.GeWsTtueFtVJMr07iJweOYpuOsMWeoFpm.KJhsM4x87TDEng4s22", validates: { presence: true }
    field :admin_salt, default: "$2a$12$.GeWsTtueFtVJMr07iJweO", validates: { presence: true }
  end

  scope :site do
    field :theme, default: "default"
    field :page_title, default: "Musician CMS", validates: { presence: true, length: { in: 2..30 } }
    field :description, default: "Application description for search engines"
    field :footer_email, default: "it.fukurokudzu@gmail.com"
    field :footer_year, default: "2024"
  end

  scope :theme do
    field :artist_title_color, default: "#ffffff"
    field :text_color, default: "#ffffff"
    field :main_menu_bg_color, default: "#16191e"
    field :footer_bg_color, default: "#16191e"
    field :player_bg_color, default: "#101011"
    field :accent_color, default: "#d35400"
    field :a_color, default: "#ffffff"
  end
end
