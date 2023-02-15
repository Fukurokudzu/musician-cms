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
    field :host, default: "http://example.com"
    field :default_locale, default: "en", validates: { presence: true }, option_values: %w[en ru]
    field :theme, default: "default"
    field :page_title, default: "Musician CMS"
    field :description, default: ""
    field :timezone, default: ""
  end
  
  scope :admin do
    field :admin_email, default: "admin@admin", validates: { presence: true }
    field :admin_password, default: "admin", validates: { presence: true }
  end
end
