class ApplicationController < ActionController::Base
  include ShortCodeLookup

  helper_method :admin?, :admin_area?
  before_action :set_page_title, :set_track
  around_action :switch_locale

  def show_flash(type = :success, message)
    flash.now[type] = message
    render turbo_stream: turbo_stream.prepend('flash_toast', partial: 'layouts/flash_toast')
  end

  private

  def admin?
    session[:hashed_id] == Setting.admin_hashed_password
  end

  def admin_area?
    controller_path.start_with?('admin')
  end

  def switch_locale(&action)
    locale = requested_locale || (locale_set? ? Setting.locale : I18n.default_locale)

    I18n.with_locale(locale, &action)
  end

  # An explicit locale parameter wins over the configured site locale, so a
  # visitor can switch the language even when the settings store a valid one.
  # ?lang= is accepted as an alias for ?locale=, since some external tools
  # (search previews, shared links) append lang= instead.
  def requested_locale
    value = (params[:locale].presence || params[:lang].presence).to_s
    value if I18n.available_locales.map(&:to_s).include?(value)
  end

  # Carry an explicit locale choice into internal links so it survives
  # navigation (and copied URLs stay in that language). A visitor arriving
  # with ?lang=ru gets links with the canonical ?locale=ru.
  def default_url_options
    options = super
    options = options.merge(locale: requested_locale) if requested_locale.present?
    options
  end

  def locale_set?
    I18n.available_locales.map(&:to_s).include?(Setting.locale)
  end

  def set_page_title
    @page_title ||= Setting.page_title || 'Musician CMS'
  end

  def set_track
    @track = active_track
    Rails.logger.warn 'No tracks available in the library' unless @track

    @release = @track&.release
    update_session_track_id if session[:current_track_id].nil? && @track&.persisted?
  end

  # Applies the submitted settings as one unit. An invalid value (for example
  # a page title below the allowed minimum) rolls the whole update back and
  # returns false with @settings_errors filled in, instead of letting
  # ActiveRecord::RecordInvalid escape into a 500.
  def update_system_settings(checked_params)
    params = checked_params.dup

    ActiveRecord::Base.transaction do
      update_admin_password_from_params!(params)
      update_settings_from_params(params)
    end
    clear_settings_cache
    true
  rescue ActiveRecord::RecordInvalid, ActiveModel::ValidationError => e
    clear_settings_cache
    @settings_errors = settings_error_messages(e)
    false
  end

  def settings_error_messages(error)
    record = error.record if error.respond_to?(:record)
    (record || error).errors.full_messages
  end

  def update_admin_password_from_params!(params)
    pw_value = params.delete(:admin_password)
    return unless pw_value.present?

    Setting.admin_hashed_password = Auth.hash_password(pw_value)
  end

  def update_settings_from_params(params)
    params.each do |key, value|
      next if value.nil?

      value = value.strip if value.respond_to?(:strip)
      Setting.public_send("#{key}=", value)
    end
    true
  end

  def clear_settings_cache
    Setting.clear_cache if Setting.respond_to?(:clear_cache)
    Rails.cache.delete_matched("rails_settings_cached/*") if Rails.cache.respond_to?(:delete_matched)
    true
  end

  def update_session_track_id
    session[:current_track_id] = @track&.id
  end

  def active_track
    session_track || random_track
  end

  def session_track
    return nil if session[:current_track_id].nil?

    Track.playable.find_by(id: session[:current_track_id])
  end

  def random_track
    @random_track ||= Track.playable.sample
  end
end
