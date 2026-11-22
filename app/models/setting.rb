# RailsSettings Model
class Setting < RailsSettings::Base
  cache_prefix { 'v1' }

  DATE_FORMATS = {
    '%d.%m.%Y' => 'DD.MM.YYYY',
    '%m/%d/%Y' => 'MM/DD/YYYY',
    '%d/%m/%Y' => 'DD/MM/YYYY',
    '%Y-%m-%d' => 'YYYY-MM-DD',
    '%-d %B %Y' => 'D Month YYYY'
  }.freeze
  DEFAULT_DATE_FORMAT = '%d.%m.%Y'.freeze

  # Define your fields
  # field :host, type: :string, default: "http://localhost:3000"
  # field :default_locale, default: "en", type: :string
  # field :confirmable_enable, default: "0", type: :boolean
  # field :admin_emails, default: "admin@rubyonrails.org", type: :array
  # field :omniauth_google_client_id, default: (ENV["OMNIAUTH_GOOGLE_CLIENT_ID"] || ""), type: :string, readonly: true
  # field :omniauth_google_client_secret, default: (ENV["OMNIAUTH_GOOGLE_CLIENT_SECRET"] || ""),
  #   type: :string, readonly: true

  scope :application do
    field :app_name, default: 'Musician CMS', validates: { presence: true, length: { in: 2..30 } }
    field :host, default: 'https://example.com'
    field :locale, default: 'en', validates: { presence: true }, option_values: %w[en ru es fr de]
    field :timezone, default: ''
    field :date_format, default: DEFAULT_DATE_FORMAT,
                        validates: { presence: true, inclusion: { in: DATE_FORMATS.keys } },
                        option_values: DATE_FORMATS.keys
    field :cover_filenames, default: %w[cover artwork], validates: { presence: true }
    field :cover_extensions, default: %w[jpg jpeg png], validates: { presence: true }
    field :track_extensions, default: %w[mp3 wav wave], validates: { presence: true }
    field :email_pattern, default: '.*@.*', validates: { presence: true }
    field :library_path, default: 'app/music', validates: { presence: true }
  end

  scope :admin do
    field :admin_email, default: 'admin@admin', validates: { presence: true }
    # default password is admin
    field :admin_hashed_password, default: '$2a$12$.GeWsTtueFtVJMr07iJweOYpuOsMWeoFpm.KJhsM4x87TDEng4s22',
                                  validates: { presence: true }
    field :admin_salt, default: '$2a$12$.GeWsTtueFtVJMr07iJweO', validates: { presence: true }
    # 0 keeps audit events forever, otherwise entries older than N days are pruned
    field :audit_retention_days, default: 90, type: :integer,
                                 validates: { numericality: { only_integer: true, greater_than_or_equal_to: 0 } }
  end

  scope :site do
    field :page_title, default: 'Musician CMS', validates: { presence: true, length: { in: 2..30 } }
    field :description, default: 'Application description for search engines'
    field :footer_email, default: 'it.fukurokudzu@gmail.com'
    field :footer_link_type, default: 'email', option_values: %w[email url]
    field :footer_subject, default: 'Musician cms'
    field :footer_url, default: ''
  end

  COLOR_FORMAT = /\A#(?:[0-9a-fA-F]{3}|[0-9a-fA-F]{4}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})\z/

  scope :theme do
    color_validation = { format: { with: COLOR_FORMAT, allow_blank: true } }

    field :artist_title_color, default: '#ffffff', validates: color_validation
    field :text_color, default: '#ffffff', validates: color_validation
    field :main_menu_bg_color, default: '#16191e', validates: color_validation
    field :footer_bg_color, default: '#16191e', validates: color_validation
    field :player_bg_color, default: '#101011', validates: color_validation
    field :accent_color, default: '#d35400', validates: color_validation
    field :a_color, default: '#ffffff', validates: color_validation
    field :a_hover_color, default: '#ffffff', validates: color_validation
    field :border_radius, default: 5,
                          validates: { numericality: { only_integer: true, greater_than_or_equal_to: 0,
                                                       less_than_or_equal_to: 50 },
                                       allow_blank: true }
    field :favicon, default: '', type: :string # ActiveStorage signed_id
    field :background_image, default: '', type: :string # ActiveStorage signed_id
  end
end
