module AdminAuthorization
  extend ActiveSupport::Concern

  # Single source of truth for admin access: controllers and route constraints
  # (for example Sidekiq::Web) must agree on what an authenticated admin is.
  def self.allowed?(session)
    session[:hashed_id].present? && session[:hashed_id] == Setting.admin_hashed_password
  end

  included do
    before_action :require_admin
  end

  private

  def require_admin
    return if admin?

    render '/sessions/new'
  end
end
