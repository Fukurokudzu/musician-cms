class ApplicationController < ActionController::Base
  helper_method :admin?
  before_action :set_page_title, :set_track, :first_run
  around_action :switch_locale

  def show_flash(type = :success, message)
    flash.now[type] = message
    render turbo_stream: turbo_stream.prepend('flash_toast', partial: 'layouts/flash_toast')
  end

  private

  def admin?
    session[:hashed_id] == Setting.admin_hashed_password
  end

  def switch_locale(&action)
    locale = if locale_set?
               Setting.locale
             elsif I18n.available_locales.map(&:to_s).include?(params[:locale])
               params[:locale] || I18n.default_locale
             else
               I18n.default_locale
             end

    I18n.with_locale(locale, &action)
  end

  def locale_set?
    I18n.available_locales.map(&:to_s).include?(Setting.locale)
  end

  def set_page_title
    @page_title ||= Setting.page_title
  end

  def set_track
    @track ||= session_track || random_track || default_track
    @release = @track.release if @track.present?

    update_session_track_id if session[:current_track_id].nil?
  end

  def update_system_settings(checked_params)
    params = checked_params.dup
    update_admin_password_from_params!(params)
    update_settings_from_params(params)
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
  end

  def update_session_track_id
    session[:current_track_id] = @track&.id
  end

  def session_track
    return nil if session[:current_track_id].nil?

    Track.find_by(id: session[:current_track_id])
  end

  def random_track
    Track.all.sample
  end

  def default_track
    Track.find_by(title: 'Default Track')
  end

  def first_run
    return unless Setting.first_run

    result = ScanLibJob.perform_now
    Setting.first_run = false
  end
end
